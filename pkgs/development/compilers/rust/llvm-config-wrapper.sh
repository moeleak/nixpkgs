#! @shell@

if [ "$#" -eq 1 ] && [ "$1" = "--bindir" ]; then
  dirname "$0"
else
  exec @real_llvm_config@ "$@"
fi
