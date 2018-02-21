import Danger

let danger = Danger()
for file in danger.git.modifiedFiles {
    print(" - " + file)
}

message("Just verifying this works")
