import { getHomeContent } from "../lib/get-home-content";

export default function HomePage() {
  const sections = getHomeContent();

  return (
    <main>
      <h1>MoaDev</h1>
      <p>One place for high-signal technology news, open-source pull requests, and follow-up actions.</p>
      <ul>
        {sections.map((section) => (
          <li key={section.id}>
            <strong>{section.title}</strong>
            <p>{section.description}</p>
          </li>
        ))}
      </ul>
    </main>
  );
}
