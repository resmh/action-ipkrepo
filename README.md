# action-ipkrepo - Create signed package index from folder

Github action to create an package index for a given directory. Setting sign to 1 will sign the package index with the provided privategpg as well as privatesignify. Input and output folder may be the same. If cache points to an existing package index file, it will be included in the resulting index. Setting strict to 1 will cause the overall action to fail if individual steps fail.

Example using repository secrets for base64 key storage:

      - name: Publish relative-input-folder to relative-output-folder
        uses: resmh/action-ipkpack@master
        with:
          input: . (relative-input-folder)
          output: . (relative-output-folder)
          privategpg: ${{ secrets.PRIVATEGPG }} (optional base64 private gpg key)
          privatesignify: ${{ secrets.PRIVATESIGNIFY }} (optional base64 private signify key)
          cache: '' (optional cached package index)
          strict: 0 (0/1)
          
Keys are generated using gpg --gen-key without setting a passphrase followed by an --armored --export-secret-key as well as signify-openbsd -G -n -p key.pub -s key.sec. They are then subjected to the base64 utility and finally configured as action secret. The resulting files are ready to use as opkg repository.
