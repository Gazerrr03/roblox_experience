local MonsterUgcReviewQueue = {}
MonsterUgcReviewQueue.__index = MonsterUgcReviewQueue

MonsterUgcReviewQueue.Status = table.freeze({
    Pending = 'Pending',
    Approved = 'Approved',
    Rejected = 'Rejected',
})

local function freezeSnapshot(entry)
    local snapshot = {
        SubmissionId = entry.SubmissionId,
        Status = entry.Status,
        SubmittedAtEpochSeconds = entry.SubmittedAtEpochSeconds,
        SubmittedByUserId = entry.SubmittedByUserId,
        ReviewedAtEpochSeconds = entry.ReviewedAtEpochSeconds,
        ReviewedBy = entry.ReviewedBy,
        RejectionCode = entry.RejectionCode,
        DecisionReason = entry.DecisionReason,
        Bundle = entry.Bundle,
    }

    return table.freeze(snapshot)
end

function MonsterUgcReviewQueue.new(options)
    local queueOptions = options or {}

    return setmetatable({
        NextId = 1,
        MaxPending = queueOptions.MaxPending or 128,
        Entries = {},
    }, MonsterUgcReviewQueue)
end

function MonsterUgcReviewQueue:_countPending()
    local pending = 0
    for _, entry in pairs(self.Entries) do
        if entry.Status == MonsterUgcReviewQueue.Status.Pending then
            pending += 1
        end
    end

    return pending
end

function MonsterUgcReviewQueue:submit(bundle, options)
    if type(bundle) ~= 'table' then
        return false, 'MalformedReviewBundle'
    end

    if type(bundle.BundleId) ~= 'string' or bundle.BundleId == '' then
        return false, 'MissingBundleId'
    end

    if type(bundle.RecipeHash) ~= 'string' or bundle.RecipeHash == '' then
        return false, 'MissingRecipeHash'
    end

    if self:_countPending() >= self.MaxPending then
        return false, 'ReviewQueueFull'
    end

    local submitOptions = options or {}
    local now = submitOptions.Now or os.time
    local submittedByUserId = submitOptions.SubmittedByUserId
    if submittedByUserId == nil then
        submittedByUserId = bundle.SubmittedByUserId
    end

    local submissionId = string.format('ugc-submission-%04d', self.NextId)
    self.NextId += 1

    local entry = {
        SubmissionId = submissionId,
        Status = MonsterUgcReviewQueue.Status.Pending,
        SubmittedAtEpochSeconds = now(),
        SubmittedByUserId = submittedByUserId,
        ReviewedAtEpochSeconds = nil,
        ReviewedBy = nil,
        RejectionCode = nil,
        DecisionReason = nil,
        Bundle = bundle,
    }

    self.Entries[submissionId] = entry
    return true, freezeSnapshot(entry)
end

function MonsterUgcReviewQueue:getSubmission(submissionId)
    local entry = self.Entries[submissionId]
    if entry == nil then
        return false, 'SubmissionNotFound'
    end

    return true, freezeSnapshot(entry)
end

function MonsterUgcReviewQueue:listPending()
    local pending = {}
    for _, entry in pairs(self.Entries) do
        if entry.Status == MonsterUgcReviewQueue.Status.Pending then
            table.insert(pending, freezeSnapshot(entry))
        end
    end

    table.sort(pending, function(left, right)
        return left.SubmissionId < right.SubmissionId
    end)

    return table.freeze(pending)
end

function MonsterUgcReviewQueue:decide(submissionId, decision, options)
    local entry = self.Entries[submissionId]
    if entry == nil then
        return false, 'SubmissionNotFound'
    end

    if entry.Status ~= MonsterUgcReviewQueue.Status.Pending then
        return false, 'SubmissionAlreadyFinalized'
    end

    if type(decision) ~= 'table' then
        return false, 'MalformedDecision'
    end

    local approve = decision.Approved == true
    local now = (options and options.Now) or os.time
    local reviewer = decision.Reviewer
    if type(reviewer) ~= 'string' or reviewer == '' then
        reviewer = 'ugc-moderator'
    end

    entry.Status = if approve
        then MonsterUgcReviewQueue.Status.Approved
        else MonsterUgcReviewQueue.Status.Rejected
    entry.ReviewedBy = reviewer
    entry.ReviewedAtEpochSeconds = now()
    entry.DecisionReason = decision.Reason
    if not approve then
        entry.RejectionCode = decision.RejectionCode or 'ManualReject'
    end

    return true, freezeSnapshot(entry)
end

return MonsterUgcReviewQueue
