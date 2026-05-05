"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";

interface BlogPost {
  slug: string;
  title: string;
  date: string;
  excerpt: string;
  tags: string[];
}

export default function BlogPage() {
  const t = useTranslations("blog");

  // Posts are defined here; later they could be loaded from MDX frontmatter
  const posts: BlogPost[] = [
    {
      slug: "the-sound-of-death",
      title: "The Sound of Death: Designing an Audio-Driven Predator",
      date: "2026-04-28",
      excerpt:
        "How we designed a threat that hunts through sound alone — and why fairness matters more than fear.",
      tags: ["design", "threats"],
    },
    {
      slug: "why-knowledge-beats-stats",
      title: "Why Knowledge Beats Stats: The Core Philosophy of Liminal",
      date: "2026-04-15",
      excerpt:
        "Liminal is not about becoming stronger. It's about becoming less blind. Here's why cognitive survival is the game's true progression system.",
      tags: ["design", "philosophy"],
    },
    {
      slug: "building-the-maze",
      title: "Building the Maze: From Graybox to Authored Death-Space",
      date: "2026-03-30",
      excerpt:
        "The Maze is not a random dungeon. It is an authored encounter grammar — every room serves a purpose in the player's experience arc.",
      tags: ["development", "level-design"],
    },
  ];

  // For now, just show the list. Blog detail pages will be added later with MDX.
  return (
    <div className="max-w-3xl mx-auto px-6 py-24">
      {/* Header */}
      <section className="text-center mb-24">
        <p className="terminal-text text-[10px] tracking-[0.4em] text-[#4a4a4a] mb-8">
          ████████████████████████████
        </p>
        <h1 className="font-mono text-4xl md:text-5xl font-bold tracking-[0.2em] text-[#e0e0e0] mb-6">
          {t("title")}
        </h1>
        <p className="terminal-text text-sm text-[#6b6b6b] tracking-[0.15em]">
          {t("subtitle")}
        </p>
      </section>

      {posts.length > 0 ? (
        <div className="space-y-12">
          {posts.map((post) => (
            <article
              key={post.slug}
              className="card-stone p-8 noise-overlay group"
            >
              <div className="flex flex-wrap gap-2 mb-3">
                {post.tags.map((tag) => (
                  <span
                    key={tag}
                    className="text-[10px] tracking-[0.1em] uppercase text-[#4a4a4a] border border-white/[0.04] px-2 py-0.5"
                  >
                    {tag}
                  </span>
                ))}
              </div>
              <h2 className="terminal-text text-lg tracking-[0.1em] text-[#e0e0e0] mb-3 group-hover:text-[#c4a35a] transition-colors">
                {post.title}
              </h2>
              <p className="text-xs text-[#4a4a4a] font-mono mb-4">
                {t("publishedOn")}: {post.date}
              </p>
              <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">
                {post.excerpt}
              </p>
              <Link
                href={`/blog/${post.slug}`}
                className="link-terminal text-xs"
              >
                [{t("readMore")}]
              </Link>
            </article>
          ))}
        </div>
      ) : (
        <div className="text-center py-24">
          <p className="terminal-text text-sm text-[#4a4a4a]">
            {t("noPosts")}
          </p>
        </div>
      )}
    </div>
  );
}
