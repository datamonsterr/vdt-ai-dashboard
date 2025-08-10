import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function Home() {
  const { userId } = auth();
  if (!userId) {
    redirect("/sign-in");
  }
  return <main className="p-6">Welcome to VDT AI</main>;
}
