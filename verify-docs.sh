#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v gpg >/dev/null 2>&1; then
  echo "Erro: gpg nao encontrado no PATH."
  exit 1
fi

MANIFEST="assinaturas/manifesto-sha256.txt"
SIGN_FILE="assinaturas/manifesto-sha256.txt.asc"
PUBKEY_FILE="assinaturas/chave-publica.asc"

for file in "$MANIFEST" "$SIGN_FILE" "$PUBKEY_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "Erro: arquivo ausente: $file"
    exit 1
  fi
done

if grep -qi "Aguardando publicacao" "$MANIFEST" "$SIGN_FILE" "$PUBKEY_FILE"; then
  echo "Artefatos oficiais ainda nao publicados."
  echo "Publique manifesto, assinatura e chave publica validos em assinaturas/."
  exit 1
fi

TMP_GNUPG="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_GNUPG"
}
trap cleanup EXIT

GNUPGHOME="$TMP_GNUPG" gpg --import "$PUBKEY_FILE" >/dev/null 2>&1
GNUPGHOME="$TMP_GNUPG" gpg --verify "$SIGN_FILE" "$MANIFEST"

echo
echo "Verificando integridade dos arquivos listados no manifesto..."

# Ignora comentarios em branco/com '#', preservando formato sha256sum.
grep -E '^[a-f0-9]{64}[[:space:]]' "$MANIFEST" | sha256sum -c -

echo
echo "OK: assinatura e integridade validadas."
