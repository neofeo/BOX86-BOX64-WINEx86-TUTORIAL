import re
import sys

def hex_to_decimal(match):
    decimal_value = int(match.group(1), 16)
    return str(decimal_value)

def decimal_to_hex(match):
    decimal_value = int(match.group(1))
    return '0x' + hex(decimal_value)[2:]

def process_file(input_filename, conversion_type):
    with open(input_filename, 'r') as infile:
        lines = infile.readlines()

    if conversion_type == "1":
        pattern = re.compile(r'0x([0-9a-fA-F]+)')
        convert_function = hex_to_decimal
    elif conversion_type == "2":
        pattern = re.compile(r'\b(?:0x)?(\d+)\b')
        convert_function = decimal_to_hex
    else:
        print("Invalid option. Choose either '1' for hex to decimal or '2' for decimal to hex.")
        sys.exit(1)

    converted_lines = []
    for line in lines:
        if line.strip().startswith("opp-hz") or line.strip().startswith("opp-microvolt"):
            converted_lines.append(pattern.sub(convert_function, line))
        else:
            converted_lines.append(line)

    with open(input_filename, 'w') as outfile:
        outfile.writelines(converted_lines)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 convert_values.py input_file")
        sys.exit(1)

    input_filename = sys.argv[1]

    conversion_type = input("Enter '1' for hex to decimal or '2' for decimal to hex: ")

    process_file(input_filename, conversion_type)

    print(f"Conversion completed. Check the file: {input_filename}")
