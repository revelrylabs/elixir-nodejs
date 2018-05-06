mix deps.get
mix hex.config username "$HEX_USERNAME"
mix hex.config encrypted_key "$HEX_ENCRYPTED_KEY" > /dev/null 2>&1
echo "$HEX_PASSPHRASE" | mix hex.publish --no-confirm
