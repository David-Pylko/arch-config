    function rotate --description "Rotate PDF files clockwise using qpdf"
        argparse 'a/angle=' -- $argv
        or return 1

        if test (count $argv) -eq 0
            echo "Usage: rotate [-a <angle>] <file.pdf ...>" >&2
            return 1
        end
        # Default to 90 degrees clockwise (+90)
        set -l angle "+90"
        if set -q _flag_angle
            set angle $_flag_angle
            # Prepend '+' if a raw number like 90 or 180 was passed
            if string match -qr '^[0-9]+$' -- $angle
                set angle "+$angle"
            end
        end

        for file in $argv

            if not test -f "$file"
                echo "Error: File '$file' not found." >&2
                continue
            end

            # Strip .pdf extension (preserving any directory path) and append -rotated.pdf
            set -l base (string replace -ri '\.pdf$' '' -- "$file")
            set -l output "$base-rotated.pdf"

            qpdf "$file" --rotate="$angle" "$output"
        end
    end
