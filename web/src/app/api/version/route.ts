import { readConfig } from "@/lib/config";
import { NextResponse } from "next/server";

export async function GET() {
  try {
    const version = await readConfig("version");
    return NextResponse.json(version);
  } catch {
    return NextResponse.json(
      { error: "Failed to read version" },
      { status: 500 }
    );
  }
}
