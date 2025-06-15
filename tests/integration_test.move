#[test_only]
module food_safety_contracts::integration_test {
    use std::string;
    use std::signer;
    use aptos_framework::timestamp;
    use food_safety_contracts::business_license;
    use food_safety_contracts::partner_x;

    #[test(admin = @food_safety_contracts, business_owner = @0x123, partner = @0x456, aptos_framework = @0x1)]
    public fun test_full_workflow(
        admin: &signer, 
        business_owner: &signer, 
        partner: &signer, 
        aptos_framework: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        
        // Initialize both modules
        business_license::init_module(admin);
        partner_x::init_module(admin);
        
        let business_owner_addr = signer::address_of(business_owner);
        let partner_addr = signer::address_of(partner);
        
        // Step 1: Issue business license
        let license_id = string::utf8(b"BIZ001");
        business_license::issue_license(
            admin,
            business_owner_addr,
            license_id,
            string::utf8(b"Green Market"),
            string::utf8(b"GOV001"),
            string::utf8(b"Grocery Store"),
            2
        );
        
        // Step 2: Issue partner license
        let partner_id = string::utf8(b"PARTNER001");
        partner_x::issue_partner_license(
            admin,
            partner_addr,
            partner_id,
            string::utf8(b"Certified Food Inspector"),
            string::utf8(b"Retail Food Safety")
        );
        
        // Step 3: Verify both licenses are active
        assert!(business_license::verify_license(license_id) == true, 1);
        assert!(partner_x::verify_partner(partner_addr) == true, 2);
        
        // Step 4: Partner submits verification for business's product
        let report_id = string::utf8(b"INSPECTION001");
        partner_x::submit_verification(
            partner,
            report_id,
            string::utf8(b"Fresh Vegetables"),
            business_owner_addr,
            string::utf8(b"COMPLIANT"),
            string::utf8(b"All safety standards met")
        );
        
        // Step 5: Verify the inspection was recorded
        let (product_name, verdict, verifier_addr, evidence, _) = 
            partner_x::get_verification_by_report_id(report_id);
        
        assert!(product_name == string::utf8(b"Fresh Vegetables"), 3);
        assert!(verdict == string::utf8(b"COMPLIANT"), 4);
        assert!(verifier_addr == partner_addr, 5);
        assert!(evidence == string::utf8(b"All safety standards met"), 6);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_expired_business_license_workflow(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        business_license::init_module(admin);
        
        let business_owner = @0x123;
        let license_id = string::utf8(b"BIZ002");
        
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
        timestamp::update_global_time_for_test(future_time);
        
        // Verify license is now expired
        assert!(business_license::verify_license(license_id) == false, 2);
    }
}