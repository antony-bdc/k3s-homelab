plugin "terraform" {
  enabled = true
  preset  = "all"
}

# One small root module: a separate main/variables/outputs layout is followed, but not every file is required.
rule "terraform_standard_module_structure" {
  enabled = false
}
