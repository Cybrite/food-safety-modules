#[test_only]
module food_safety_contracts::business_license_test {
    use std::string;
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use food_safety_contracts::business_license;

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_complete_workflow(admin: &signer, aptos_framework: &signer) {
        // Set up test environment
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        
        // Initialize the registry
        business_license::create_registry(admin);
        
        // Verify registry is created
        assert!(business_license::registry_exists(signer::address_of(admin)), 1);
        
        // Issue a license
        let business_owner = @0x123;
        let license_id = string::utf8(b"LIC001");
        let business_name = string::utf8(b"Test Restaurant");
        let government_id = string::utf8(b"GOV123");
        let business_type = string::utf8(b"Restaurant");
        let validity_years = 2;

        business_license::issue_license(
            admin,
            business_owner,
            license_id,
            business_name,
            government_id,
            business_type,
            validity_years
        );

        // Verify license was issued correctly
        let (name, biz_type, owner, is_active) = business_license::get_license_by_id(license_id);
        assert!(name == business_name, 2);
        assert!(biz_type == business_type, 3);
        assert!(owner == business_owner, 4);
        assert!(is_active == true, 5);
        
        // Verify license is valid
        assert!(business_license::verify_license(license_id) == true, 6);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_license_expiry(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        business_license::create_registry(admin);
        
        let business_owner = @0x123;
        let license_id = string::utf8(b"LIC002");
        
        // Issue short-term license
        business_license::issue_license(
            admin,
            business_owner,
            license_id,
            string::utf8(b"Temp Restaurant"),
            string::utf8(b"GOV002"),
            string::utf8(b"Restaurant"),
            1 // 1 year validity
        );
        
        // Verify license is initially valid
        assert!(business_license::verify_license(license_id) == true, 1);
        
        // Fast forward time to expire the license
        let future_time = timestamp::now_seconds() + (2 * 365 * 24 * 60 * 60); // 2 years
        timestamp::update_global_time_for_test_secs(future_time);
        
        // Verify license is now expired
        assert!(business_license::verify_license(license_id) == false, 2);
    }

    #[test(admin = @food_safety_contracts)]
    #[expected_failure(abort_code = 2, location = food_safety_contracts::business_license)]
    public fun test_get_license_by_id_not_found(admin: &signer) {
        account::create_account_for_test(signer::address_of(admin));
        business_license::create_registry(admin);
        
        let non_existent_id = string::utf8(b"NONEXISTENT");
        business_license::get_license_by_id(non_existent_id);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_verify_license_not_found(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        business_license::create_registry(admin);
        
        let non_existent_id = string::utf8(b"NONEXISTENT");
        assert!(business_license::verify_license(non_existent_id) == false, 1);
    }

    #[test(non_admin = @0x999)]
    #[expected_failure(abort_code = 1, location = food_safety_contracts::business_license)]
    public fun test_unauthorized_license_issuance(non_admin: &signer) {
        account::create_account_for_test(signer::address_of(non_admin));
        
        // Try to create registry as non-admin - should fail
        business_license::create_registry(non_admin);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 3, location = food_safety_contracts::business_license)]
    public fun test_invalid_validity_years(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        business_license::create_registry(admin);
        
        // Try to issue license with 0 validity years
        business_license::issue_license(
            admin,
            @0x123,
            string::utf8(b"LIC003"),
            string::utf8(b"Test Business"),
            string::utf8(b"GOV003"),
            string::utf8(b"Restaurant"),
            0 // Invalid validity
        );
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_verify_license_with_no_registry(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(admin));
        
        // Don't create registry, just try to verify
        let license_id = string::utf8(b"LIC004");
        assert!(business_license::verify_license(license_id) == false, 1);
    }
}