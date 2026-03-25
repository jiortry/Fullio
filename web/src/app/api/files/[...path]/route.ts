import { readSwiftFile, writeSwiftFile } from "@/lib/config";
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path: pathSegments } = await params;
  const filePath = pathSegments.join("/");

  try {
    const content = await readSwiftFile(filePath);
    return NextResponse.json({
      path: filePath,
      content,
      lines: content.split("\n").length,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to read file";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path: pathSegments } = await params;
  const filePath = pathSegments.join("/");

  try {
    const { content } = await request.json();
    if (typeof content !== "string") {
      return NextResponse.json(
        { error: "Content must be a string" },
        { status: 400 }
      );
    }

    await writeSwiftFile(filePath, content);
    return NextResponse.json({ success: true, path: filePath });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to write file";
    const isVercel =
      message.includes("Vercel") || message.includes("non supportata");
    return NextResponse.json(
      { error: message },
      { status: isVercel ? 501 : 400 }
    );
  }
}
