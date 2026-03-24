import { listSwiftFiles } from "@/lib/config";
import { NextResponse } from "next/server";

export async function GET() {
  try {
    const files = await listSwiftFiles();
    const tree = buildTree(files);
    return NextResponse.json({ files, tree });
  } catch {
    return NextResponse.json(
      { error: "Failed to list files" },
      { status: 500 }
    );
  }
}

interface TreeNode {
  name: string;
  path: string;
  type: "file" | "folder";
  children?: TreeNode[];
}

function buildTree(paths: string[]): TreeNode[] {
  const root: TreeNode[] = [];

  for (const filePath of paths) {
    const parts = filePath.split("/");
    let current = root;

    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      const isFile = i === parts.length - 1;
      const currentPath = parts.slice(0, i + 1).join("/");

      let existing = current.find((n) => n.name === part);
      if (!existing) {
        existing = {
          name: part,
          path: currentPath,
          type: isFile ? "file" : "folder",
          ...(isFile ? {} : { children: [] }),
        };
        current.push(existing);
      }
      if (!isFile && existing.children) {
        current = existing.children;
      }
    }
  }

  return root;
}
