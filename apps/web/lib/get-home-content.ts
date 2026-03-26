export type HomeSection = {
  id: "news" | "prs" | "actions";
  title: string;
  description: string;
};

export function getHomeContent(): HomeSection[] {
  return [
    {
      id: "news",
      title: "Global technology news",
      description: "Curated stories that matter to developers without the surrounding noise.",
    },
    {
      id: "prs",
      title: "Open-source pull request activity",
      description: "Promising repositories and pull requests worth tracking or contributing to.",
    },
    {
      id: "actions",
      title: "Action-ready follow-up",
      description: "Structured next steps that turn insight into review, tracking, and execution.",
    },
  ];
}
