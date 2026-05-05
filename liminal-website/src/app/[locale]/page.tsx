import { getTranslations } from "next-intl/server";
import LandingHero from "@/components/home/LandingHero";
import ChapterSection from "@/components/home/ChapterSection";
import DarknessScene from "@/components/home/scenes/DarknessScene";
import CataclysmScene from "@/components/home/scenes/CataclysmScene";
import MazeScene from "@/components/home/scenes/MazeScene";
import ProhibitionsScene from "@/components/home/scenes/ProhibitionsScene";
import QuestionScene from "@/components/home/scenes/QuestionScene";

export default async function HomePage() {
  const t = await getTranslations("home");

  return (
    <div>
      <LandingHero tagline={t("heroTagline")} />

      <ChapterSection
        scene={DarknessScene}
        chapterNumber={1}
        chapterTitle={t("chapter1Title")}
        texts={[
          { text: t("chapter1P1"), threshold: 0.1 },
          { text: t("chapter1P2"), threshold: 0.35 },
        ]}
      />

      <ChapterSection
        scene={CataclysmScene}
        chapterNumber={2}
        chapterTitle={t("chapter2Title")}
        texts={[
          { text: t("chapter2P1"), threshold: 0.1 },
          { text: t("chapter2P2"), threshold: 0.35 },
        ]}
      />

      <ChapterSection
        scene={MazeScene}
        chapterNumber={3}
        chapterTitle={t("chapter3Title")}
        texts={[
          { text: t("chapter3P1"), threshold: 0.1 },
          { text: t("chapter3P2"), threshold: 0.35 },
        ]}
      />

      <ChapterSection
        scene={ProhibitionsScene}
        chapterNumber={4}
        chapterTitle={t("chapter4Title")}
        texts={[
          { text: t("chapter4P1"), threshold: 0.1 },
          { text: t("chapter4P2"), threshold: 0.35 },
        ]}
      />

      <ChapterSection
        scene={QuestionScene}
        chapterNumber={5}
        chapterTitle={t("chapter5Title")}
        texts={[
          { text: t("chapter5P1"), threshold: 0.1 },
          { text: t("chapter5P2"), threshold: 0.35 },
        ]}
      />
    </div>
  );
}
