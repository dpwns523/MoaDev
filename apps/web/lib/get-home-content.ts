export type HomeSection = {
  id: "news" | "prs" | "actions";
  title: string;
  description: string;
};

export function getHomeContent(): HomeSection[] {
  return [
    {
      id: "news",
      title: "Signal desk",
      description: "Major product, platform, and tooling changes filtered into a quieter editorial brief.",
    },
    {
      id: "prs",
      title: "Review queue",
      description: "Open-source pull requests with enough context to decide whether to watch, review, or jump in.",
    },
    {
      id: "actions",
      title: "Follow-up map",
      description: "Structured next steps that turn reading into triage, comments, and execution.",
    },
  ];
}
