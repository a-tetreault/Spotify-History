import json


fname = input("Enter file to scrub: ")
if fname.lower() == 'exit':
    raise SystemExit

if not fname:
    print("BONK! not a real file")
    fname = input("Enter filename: ")
print("Retrieving", fname)

key_to_remove = input("Which field would you like to remove? ")
new_file = list()

with open(fname, encoding = "UTF-8") as handle:
    try:
        json_data = json.load(handle)

    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")

    if isinstance(json_data, list): # if the json data you pull is a list then try to load it
        for item in json_data:
            if key_to_remove in item.keys():

                updated_data = { key : value for key, value in item.items() if key != key_to_remove }
                removed_value = item[key_to_remove]
                print(f"Removed key '{key_to_remove}' with value: {removed_value}")

                new_file.append(updated_data)
                print(f"Added ' {updated_data} ' to file to be written")

            else:
                print("Key does not exist!")


with open(fname, 'w', encoding = "UTF-8") as file:
    json.dump(new_file, file, indent=4)
    print("Writing file. One moment please!")

