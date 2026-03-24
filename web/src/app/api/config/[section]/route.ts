import { readConfig, writeConfig, bumpVersion, type ConfigSection } from "@/lib/config";
import { NextRequest, NextResponse } from "next/server";

const VALID_SECTIONS: ConfigSection[] = [
  "version",
  "theme",
  "categories",
  "strings",
  "features",
];

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ section: string }> }
) {
  const { section } = await params;
  if (!VALID_SECTIONS.includes(section as ConfigSection)) {
    return NextResponse.json({ error: "Invalid section" }, { status: 400 });
  }

  try {
    const data = await readConfig(section as ConfigSection);
    return NextResponse.json(data);
  } catch {
    return NextResponse.json(
      { error: "Failed to read config" },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ section: string }> }
) {
  const { section } = await params;
  if (!VALID_SECTIONS.includes(section as ConfigSection)) {
    return NextResponse.json({ error: "Invalid section" }, { status: 400 });
  }

  if (section === "version") {
    return NextResponse.json(
      { error: "Version is auto-managed. Use bump endpoint." },
      { status: 400 }
    );
  }

  try {
    const body = await request.json();
    await writeConfig(section as ConfigSection, body);
    const newVersion = await bumpVersion(`Updated ${section}`);
    return NextResponse.json({
      success: true,
      section,
      newVersion: newVersion.version,
    });
  } catch {
    return NextResponse.json(
      { error: "Failed to update config" },
      { status: 500 }
    );
  }
}
