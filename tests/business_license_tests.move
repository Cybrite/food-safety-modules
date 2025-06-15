#[test_only]
module food_safety_contracts::business_license_tests {
    use food_safety_contracts::business_license;
    use std::string;
    use aptos_framework::timestamp;

    #[test(admin = @food_safety_contracts)]
    public fun test_issue_business_license(admin: signer) {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&admin);
        
        // Initialize the module
        business_license::init_module(&admin);
        
        // Test issuing a license
        let current_time = timestamp::now_seconds();
        let expiry_time = current_time + 31536000; // 1 year from now
        
        business_license::issue_license(
            &admin,
            @0x123,
            string::utf8(b"LIC001"),
            string::utf8(b"Test Restaurant"),
            string::utf8(b"GOV123"),
            string::utf8(b"Restaurant"),
            expiry_time
        );
        
        // Verify the license by license ID (string), not address
        assert!(business_license::verify_license(string::utf8(b"LIC001")), 0);
        
        // Get license details - returns a tuple, not a struct
        let (business_name, owner_addr, is_active, expiry) = business_license::get_license_by_id(string::utf8(b"LIC001"));
        assert!(is_active, 1);
        assert!(owner_addr == @0x123, 2);
    }

    #[test(admin = @food_safety_contracts)]
    #[expected_failure(abort_code = 3)] // E_INVALID_EXPIRY_DATE
    public fun test_issue_license_invalid_expiry(admin: signer) {
        timestamp::set_time_has_started_for_testing(&admin);
        business_license::init_module(&admin);
        
        let current_time = timestamp::now_seconds();
        let past_time = current_time - 1000; // Past time
        
        business_license::issue_license(
            &admin,
            @0x123,
            string::utf8(b"LIC001"),
            string::utf8(b"Test Restaurant"),
            string::utf8(b"GOV123"),
            string::utf8(b"Restaurant"),
            past_time // Should fail with invalid expiry
        );
    }
}