#[test_only]
module food_safety_contracts::partner_x_test {
    use std::string;
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use food_safety_contracts::partner_x;

    #[test(admin = @food_safety_contracts, partner = @0x456, aptos_framework = @0x1)]
    public fun test_complete_partner_workflow(admin: &signer, partner: &signer, aptos_framework: &signer) {
        // Set up test environment
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(partner));
        
        // Initialize the registry
        partner_x::create_registry(admin);
        
        // Verify registry is created
        assert!(partner_x::registry_exists(signer::address_of(admin)), 1);
        
        let partner_address = signer::address_of(partner);
        let partner_id = string::utf8(b"PARTNER001");
        let credentials = string::utf8(b"PhD in Food Science");
        let specialization = string::utf8(b"Food Safety Inspector");

        // Issue partner license
        partner_x::issue_partner_license(
            admin,
            partner_address,
            partner_id,
            credentials,
            specialization
        );

        // Verify partner is registered and active
        assert!(partner_x::verify_partner(partner_address) == true, 2);

        // Submit verification
        let report_id = string::utf8(b"REPORT001");
        let product_name = string::utf8(b"Organic Milk");
        let reporter_address = @0x789;
        let verdict = string::utf8(b"SAFE");
        let evidence = string::utf8(b"Lab test results show no contamination");

        partner_x::submit_verification(
            partner,
            report_id,
            product_name,
            reporter_address,
            verdict,
            evidence
        );

        // Verify the verification was recorded
        let (prod_name, ver_verdict, ver_partner, ver_evidence, _timestamp) = 
            partner_x::get_verification_by_report_id(report_id);
        
        assert!(prod_name == product_name, 3);
        assert!(ver_verdict == verdict, 4);
        assert!(ver_partner == partner_address, 5);
        assert!(ver_evidence == evidence, 6);
    }

    #[test(admin = @food_safety_contracts, unauthorized_partner = @0x999, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 1, location = food_safety_contracts::partner_x)]
    public fun test_submit_verification_unauthorized(admin: &signer, unauthorized_partner: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(unauthorized_partner));
        partner_x::create_registry(admin);
        
        // Try to submit verification without being a registered partner
        let report_id = string::utf8(b"REPORT002");
        let product_name = string::utf8(b"Chicken Breast");
        let reporter_address = @0x789;
        let verdict = string::utf8(b"UNSAFE");
        let evidence = string::utf8(b"High bacteria count");

        partner_x::submit_verification(
            unauthorized_partner,
            report_id,
            product_name,
            reporter_address,
            verdict,
            evidence
        );
    }

    #[test(admin = @food_safety_contracts)]
    #[expected_failure(abort_code = 3, location = food_safety_contracts::partner_x)]
    public fun test_get_verification_by_report_id_not_found(admin: &signer) {
        account::create_account_for_test(signer::address_of(admin));
        partner_x::create_registry(admin);
        
        let non_existent_report = string::utf8(b"NONEXISTENT");
        partner_x::get_verification_by_report_id(non_existent_report);
    }
}