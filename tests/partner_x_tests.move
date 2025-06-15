#[test_only]
module food_safety_contracts::partner_x_tests {
    use food_safety_contracts::partner_x;
    use std::string;
    use aptos_framework::timestamp;

    #[test(admin = @food_safety_contracts)]
    public fun test_issue_partner_license(admin: signer) {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&admin);
        
        // Initialize the module
        partner_x::init_module(&admin);
        
        // Test issuing a license - use correct number of parameters
        partner_x::issue_partner_license(
            &admin,
            @0x123,
            string::utf8(b"PARTNER001"),
            string::utf8(b"Food Safety Expert")
        );
        
        // Verify the partner
        assert!(partner_x::verify_partner(@0x123), 0);
    }

    #[test(admin = @food_safety_contracts)]
    public fun test_submit_verification(admin: signer) {
        timestamp::set_time_has_started_for_testing(&admin);
        partner_x::init_module(&admin);
        
        // First issue a partner license
        partner_x::issue_partner_license(
            &admin,
            @0x123,
            string::utf8(b"PARTNER001"),
            string::utf8(b"Food Safety Expert")
        );
        
        // Then submit a verification
        partner_x::submit_verification(
            &admin, // assuming admin can submit on behalf
            @0x123, // partner address
            string::utf8(b"REPORT001"),
            string::utf8(b"Test Product"),
            @0x456, // reporter address
            string::utf8(b"SAFE"),
            string::utf8(b"Lab analysis completed")
        );
    }
}