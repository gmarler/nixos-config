{ pkgs, inputs, ... }:

{
  # Proxies for use inside MacOS running nodeproxy behind BBVPN
  networking.proxy.default = "http://10.211.55.2:8888/";
  networking.proxy.default = "127.0.0.1,localhost,internal.domain";

  # Add CA Certificates for Bloomberg's MITM proxy
  security.pki.certificateFiles = [
    ./ca_certificates/Bloomberg_LP_CORP_CLASS_1_ROOT_G2.crt
    ./ca_certificates/DigiCert_Assured_ID_CA-1.crt
    ./ca_certificates/DigiCert_Assured_ID_Code_Signing_CA-1.crt
    ./ca_certificates/DigiCert_Assured_ID_Root_CA.crt
    ./ca_certificates/DigiCert_Assured_ID_Root_G2.crt
    ./ca_certificates/DigiCert_Assured_ID_Root_G3.crt
    ./ca_certificates/DigiCert_Document_Signing_CA.crt
    ./ca_certificates/DigiCert_ECC_Extended_Validation_Server_CA.crt
    ./ca_certificates/DigiCert_EV_Code_Signing_CA.crt
    ./ca_certificates/DigiCert_EV_Code_Signing_CA_SHA2.crt
    ./ca_certificates/DigiCert_Federated_ID_Root_CA.crt
    ./ca_certificates/DigiCert_Global_Root_CA.crt
    ./ca_certificates/DigiCert_Global_Root_G2.crt
    ./ca_certificates/DigiCert_Global_Root_G3.crt
    ./ca_certificates/DigiCert_High_Assurance_Code_Signing_CA-1.crt
    ./ca_certificates/DigiCert_High_Assurance_EV_Root_CA.crt
    ./ca_certificates/DigiCert_Private_Services_Root.crt
    ./ca_certificates/DigiCert_SHA2_Assured_ID_CA.crt
    ./ca_certificates/DigiCert_SHA2_Assured_ID_Code_Signing_CA.crt
    ./ca_certificates/DigiCert_SHA2_Extended_Validation_Server_CA.crt
    ./ca_certificates/DigiCert_SHA2_High_Assurance_Code_Signing_CA.crt
    ./ca_certificates/DigiCert_TLS_RSA_SHA256_2020_CA1.crt
    ./ca_certificates/DigiCert_Trusted_Root_G4.crt
    ./ca_certificates/System_Security_Internal_Server_SubCA.crt
    ./ca_certificates/System_Security_Root_CA.crt
    ./ca_certificates/System_Security_Root_CA_G2.crt
  ];

  # https://github.com/nix-community/home-manager/pull/2408
  # environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  # programs.fish.enable = true;

  users.users.gmarler = {
    isNormalUser = true;
    home = "/home/gmarler";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.bash;
    hashedPassword = "$6$jIDA114ReF4SZBR7$.ZjVejWyhNWU3Ay8f6eE7pZumkq9eR9LEuGZhUjWvctlS8.7jVDMSYYWOtzBJUYzil73BSewba7p.NYcBcxX2/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5fREXitBB7nv0A2U8w/DFF+1Tpz4qi0pegNOWR9EkO gmarler@P2VGXFT7PT"
    ];
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
