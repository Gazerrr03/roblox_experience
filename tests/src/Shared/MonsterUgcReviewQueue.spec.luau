return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local monsters = gameplay.Monsters
    local ugcPipeline = monsters.MonsterUgcPipeline
    local reviewQueueModule = monsters.MonsterUgcReviewQueue

    local brief = {
        Prompt = '做一个会持续追击最近玩家的怪物',
        Goal = '在迷宫中制造压迫追逐',
        Experience = '玩家需要不断绕路来躲避',
        SuccessCriteria = {
            '怪物能稳定追踪最近玩家',
        },
        Semantics = {
            Lore = '来自废墟深处的机械怨灵，会追踪脚步声。',
            Atmosphere = 'Dread',
            TriggerIntentSummary = '探索开始后在关键路线附近巡游并追击。',
            CounterplayIntentSummary = '利用复杂地形遮挡视线并延迟其接近速度。',
        },
    }

    local generationOk, generationResult = ugcPipeline.generateForSandbox(brief, {
        Seed = 1001,
        PlayerUserId = 5150,
        AssetValidator = function()
            return true, 'AllowedForSandbox'
        end,
        Now = function()
            return 1710001000
        end,
    })
    assert(generationOk == true, 'Review queue tests require a sandbox-ready generation result')

    local bundleOk, bundle = ugcPipeline.buildReviewBundle(generationResult, {
        EncounterCount = 7,
        AverageChaseSeconds = 11.2,
        PlayerReportCount = 1,
        AverageSurvivalSeconds = 36.7,
    }, {
        SubmittedByUserId = 5150,
        Now = function()
            return 1710001100
        end,
    })
    assert(bundleOk == true, 'Review queue tests require a valid review bundle')

    local queue = reviewQueueModule.new({
        MaxPending = 2,
    })

    local submitOk, submission = queue:submit(bundle, {
        SubmittedByUserId = 5150,
        Now = function()
            return 1710001200
        end,
    })
    assert(submitOk == true, 'Valid bundles should be accepted by the review queue')
    assert(
        submission.Status == reviewQueueModule.Status.Pending,
        'New submissions should enter pending state'
    )

    local getOk, fetched = queue:getSubmission(submission.SubmissionId)
    assert(getOk == true, 'Submitted entries should be queryable')
    assert(
        fetched.Bundle.RecipeHash == bundle.RecipeHash,
        'Submission snapshots should preserve the attached review bundle'
    )

    local pendingEntries = queue:listPending()
    assert(#pendingEntries == 1, 'Queue should report one pending submission')

    local rejectOk, rejected = queue:decide(submission.SubmissionId, {
        Approved = false,
        Reviewer = 'moderator-alpha',
        RejectionCode = 'PolicyViolation',
        Reason = 'Contains restricted external branding in uploaded asset.',
    }, {
        Now = function()
            return 1710001300
        end,
    })
    assert(rejectOk == true, 'Moderator decisions should finalize pending entries')
    assert(
        rejected.Status == reviewQueueModule.Status.Rejected,
        'Rejected decisions should update submission status'
    )
    assert(
        rejected.RejectionCode == 'PolicyViolation',
        'Rejected decisions should preserve structured rejection code'
    )

    local secondDecisionOk, secondDecisionReason = queue:decide(submission.SubmissionId, {
        Approved = true,
    })
    assert(
        secondDecisionOk == false and secondDecisionReason == 'SubmissionAlreadyFinalized',
        'Finalized submissions should reject repeated moderator decisions'
    )

    local missingSubmissionOk, missingSubmissionReason = queue:getSubmission('ugc-submission-9999')
    assert(
        missingSubmissionOk == false and missingSubmissionReason == 'SubmissionNotFound',
        'Querying unknown submissions should return SubmissionNotFound'
    )

    local malformedSubmitOk, malformedSubmitReason = queue:submit({})
    assert(
        malformedSubmitOk == false and malformedSubmitReason == 'MissingBundleId',
        'Malformed bundles should fail with a deterministic reason'
    )
end
