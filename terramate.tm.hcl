terramate {
  config {
    git {
      default_remote = "origin"
      default_branch = "main"
      check_remote   = false   # demo runs on any clone without a live origin/<default_branch>
    }
    experiments = ["outputs-sharing"]
  }
}
