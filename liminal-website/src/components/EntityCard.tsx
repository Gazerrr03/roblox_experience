import { useLocale } from "next-intl";

interface EntityCardProps {
  id: string;
  name: { zh: string; en: string };
  subtitle: string;
  tag?: string;
  active?: boolean;
  onClick: () => void;
}

export default function EntityCard({ name, subtitle, tag, active, onClick }: EntityCardProps) {
  const locale = useLocale();
  const displayName = locale === "zh" ? name.zh : name.en;

  return (
    <button
      onClick={onClick}
      className={`card-stone p-5 text-left w-full transition-all duration-300 noise-overlay ${
        active
          ? "border-[#c4a35a]/40 shadow-[0_0_20px_rgba(196,163,90,0.1)]"
          : "hover:border-[#c4a35a]/20 hover:shadow-[0_0_15px_rgba(196,163,90,0.05)]"
      }`}
    >
      <div className="flex items-start justify-between mb-2">
        <span className="terminal-text text-xs tracking-[0.15em] text-[#c4a35a]">
          {displayName}
        </span>
        {tag && (
          <span className="text-[9px] text-[#4a4a4a] font-mono tracking-[0.1em]">{tag}</span>
        )}
      </div>
      <p className="text-[10px] text-[#4a4a4a] font-mono tracking-[0.1em] leading-relaxed line-clamp-2">
        {subtitle}
      </p>
      <div className="w-6 h-px bg-[#2a2520] mt-3 group-hover:w-10 transition-all duration-500" />
    </button>
  );
}
