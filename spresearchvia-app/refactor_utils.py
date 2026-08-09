import os
import re


def remove_comments(text):
    def replacer(match):
        s = match.group(0)
        if s.startswith("/"):
            return " "
        else:
            return s

    pattern = re.compile(
        r'//.*?$|/\*.*?\*/|\'(?:\\.|[^\\\'])*\'|"(?:\\.|[^\\"])*"',
        re.DOTALL | re.MULTILINE,
    )
    return re.sub(pattern, replacer, text)


def scan_multiple_classes(root_dir):
    print(f"Scanning {root_dir} for multiple classes...")
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                        # Remove comments first to avoid false positives
                        content_no_comments = remove_comments(content)
                        # Count top-level classes
                        # We look for "class ClassName"
                        # This might catch State classes which are usually in the same file.
                        # We should probably ignore classes that start with "_" (private) or end with "State" if we want to be lenient,
                        # but the user said "One file should contain one class".
                        # However, State classes MUST be in the same file as StatefulWidget.
                        # So we should ignore classes that extend State<T>.

                        matches = re.finditer(
                            r"\bclass\s+(\w+)(?:\s+extends\s+([\w<>]+))?",
                            content_no_comments,
                        )
                        classes = []
                        for m in matches:
                            class_name = m.group(1)
                            extends_clause = m.group(2)

                            # Ignore State classes usually named _...State
                            if class_name.startswith("_") and class_name.endswith(
                                "State"
                            ):
                                continue

                            classes.append(class_name)

                        if len(classes) > 1:
                            print(
                                f"{path}: {len(classes)} classes ({', '.join(classes)})"
                            )
                except Exception as e:
                    print(f"Error reading {path}: {e}")


def clean_comments(root_dir):
    print(f"Removing comments from {root_dir}...")
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()

                    new_content = remove_comments(content)

                    # Also remove empty lines that might have been left behind
                    # new_content = re.sub(r'\n\s*\n', '\n', new_content)
                    # User didn't explicitly ask to remove empty lines, but it's good practice.
                    # But let's stick to removing comments first.

                    if new_content != content:
                        with open(path, "w", encoding="utf-8") as f:
                            f.write(new_content)
                        print(f"Cleaned {path}")
                except Exception as e:
                    print(f"Error processing {path}: {e}")


if __name__ == "__main__":
    import sys

    mode = sys.argv[1] if len(sys.argv) > 1 else "scan"
    target_dir = "lib"

    if mode == "scan":
        scan_multiple_classes(target_dir)
    elif mode == "clean":
        clean_comments(target_dir)
