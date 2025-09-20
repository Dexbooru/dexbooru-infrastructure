#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PRE_COMMIT_VERSION="${PRE_COMMIT_VERSION:-3.7.1}"
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.9.5}"
TFLINT_VERSION="${TFLINT_VERSION:-0.53.0}"
TFLINT_SHA256="${TFLINT_SHA256:-}"
INSTALL_SCOPE="${INSTALL_SCOPE:-user}"

err() { printf >&2 "error: %s\n" "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
os() { uname -s; }
arch() { uname -m; }

install_pre_commit() {
  if have pre-commit; then return; fi
  if have brew; then
    brew install pre-commit
    return
  fi
  if have pipx; then
    pipx install "pre-commit==${PRE_COMMIT_VERSION}"
    return
  fi
  if have pip; then
    if [[ "$INSTALL_SCOPE" == "user" ]]; then pip install --user "pre-commit==${PRE_COMMIT_VERSION}"; else sudo pip install "pre-commit==${PRE_COMMIT_VERSION}"; fi
    return
  fi
  if have pacman; then
    sudo pacman -Sy --noconfirm --needed python-pre-commit
    return
  fi
  if have apt-get; then
    sudo apt-get update
    sudo apt-get install -y python3-pip python3-venv
    pip3 install --user "pre-commit==${PRE_COMMIT_VERSION}"
    return
  fi
  err "cannot install pre-commit"
}

install_terraform() {
  if have terraform && [[ "$(terraform version -json | sed -n 's/.*"terraform_version": "\(.*\)".*/\1/p')" == "${TERRAFORM_VERSION}" ]]; then return; fi
  case "$(os)" in
    Darwin)
      if have brew; then
        brew install hashicorp/tap/terraform@${TERRAFORM_VERSION} || brew install hashicorp/tap/terraform
        return
      fi
      err "homebrew required on macOS"
      ;;
    Linux)
      if have pacman; then
        sudo pacman -Sy --noconfirm --needed terraform
        return
      fi
      if have apt-get; then
        tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
        v="${TERRAFORM_VERSION}"; a="$(arch)"
        case "$a" in x86_64) tf_arch=amd64;; aarch64) tf_arch=arm64;; armv7l) tf_arch=arm;; *) err "unsupported arch $a";; esac
        url="https://releases.hashicorp.com/terraform/${v}/terraform_${v}_linux_${tf_arch}.zip"
        sum_url="https://releases.hashicorp.com/terraform/${v}/terraform_${v}_SHA256SUMS"
        curl -fsSL -o "$tmpd/terraform.zip" "$url"
        curl -fsSL -o "$tmpd/SHA256SUMS" "$sum_url"
        (cd "$tmpd" && grep "terraform_${v}_linux_${tf_arch}.zip" SHA256SUMS | sha256sum -c -)
        unzip -o "$tmpd/terraform.zip" -d "$tmpd"
        if [[ "$INSTALL_SCOPE" == "user" ]]; then
          mkdir -p "$HOME/.local/bin"
          install -m 0755 "$tmpd/terraform" "$HOME/.local/bin/terraform"
        else
          sudo install -m 0755 "$tmpd/terraform" /usr/local/bin/terraform
        fi
        return
      fi
      if have dnf || have yum; then
        tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
        v="${TERRAFORM_VERSION}"; a="$(arch)"
        case "$a" in x86_64) tf_arch=amd64;; aarch64) tf_arch=arm64;; armv7l) tf_arch=arm;; *) err "unsupported arch $a";; esac
        url="https://releases.hashicorp.com/terraform/${v}/terraform_${v}_linux_${tf_arch}.zip"
        sum_url="https://releases.hashicorp.com/terraform/${v}/terraform_${v}_SHA256SUMS"
        curl -fsSL -o "$tmpd/terraform.zip" "$url"
        curl -fsSL -o "$tmpd/SHA256SUMS" "$sum_url"
        (cd "$tmpd" && grep "terraform_${v}_linux_${tf_arch}.zip" SHA256SUMS | sha256sum -c -)
        unzip -o "$tmpd/terraform.zip" -d "$tmpd"
        if [[ "$INSTALL_SCOPE" == "user" ]]; then
          mkdir -p "$HOME/.local/bin"
          install -m 0755 "$tmpd/terraform" "$HOME/.local/bin/terraform"
        else
          sudo install -m 0755 "$tmpd/terraform" /usr/local/bin/terraform
        fi
        return
      fi
      err "unsupported Linux distro"
      ;;
    *)
      err "unsupported OS"
      ;;
  esac
}

install_tflint() {
  if have tflint && [[ "$(tflint --version | awk '{print $2}')" == "v${TFLINT_VERSION}" ]]; then return; fi
  case "$(os)" in
    Darwin)
      if have brew; then
        brew install tflint
        return
      fi
      err "homebrew required on macOS"
      ;;
    Linux)
      if have pacman; then
        sudo pacman -Sy --noconfirm --needed tflint
        return
      fi
      tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
      a="$(arch)"
      case "$a" in x86_64) tf_arch=linux_amd64;; aarch64) tf_arch=linux_arm64;; armv7l) tf_arch=linux_armv7;; *) err "unsupported arch $a";; esac
      v="${TFLINT_VERSION#v}"
      tarball="tflint_${v}_${tf_arch}.zip"
      url="https://github.com/terraform-linters/tflint/releases/download/v${v}/${tarball}"
      curl -fsSL -o "$tmpd/${tarball}" "$url"
      if [[ -n "$TFLINT_SHA256" ]]; then
        echo "${TFLINT_SHA256}  ${tmpd}/${tarball}" | sha256sum -c -
      fi
      unzip -o "$tmpd/${tarball}" -d "$tmpd"
      if [[ "$INSTALL_SCOPE" == "user" ]]; then
        mkdir -p "$HOME/.local/bin"
        install -m 0755 "$tmpd/tflint" "$HOME/.local/bin/tflint"
      else
        sudo install -m 0755 "$tmpd/tflint" /usr/local/bin/tflint
      fi
      ;;
    *)
      err "unsupported OS"
      ;;
  esac
}

main() {
  install_pre_commit
  install_terraform
  install_tflint
  if have pre-commit; then pre-commit --version >/dev/null; fi
  if have terraform; then terraform version >/dev/null; fi
  if have tflint; then tflint --version >/dev/null; fi
  echo "ok"
}

main
