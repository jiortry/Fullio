import { readAllConfigs } from "@/lib/config";
import { NextResponse } from "next/server";

export async function GET() {
  try {
    const configs = await readAllConfigs();
    return NextResponse.json(configs);
  } catch {
    return NextResponse.json(
      { error: "Failed to read configs" },
      { status: 500 }
    );
  }
}
