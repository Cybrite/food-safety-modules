#[test_only]
module food_safety_contracts::business_license_test {
    use std::string;
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use food_safety_contracts::business_license;

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_init_module(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        business_license::init_module(admin);
        
        // Verify that the registry is initialized
        assert!(exists<business_license::LicenseRegistry>(@food_safety_contracts), 1);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_issue_license_success(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        business_license::init_module(admin);
        
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

        // Verify license was issued
        let (name, biz_type, owner, is_active) = business_license::get_license_by_id(license_id);
        assert!(name == business_name, 2);
        assert!(biz_type == business_type, 3);
        assert!(owner == business_owner, 4);
        assert!(is_active == true, 5);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_verify_license_valid(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        business_license::init_module(admin);
        
        let business_owner = @0x123;
        let license_id = string::utf8(b"LIC002");
        let business_name = string::utf8(b"Test Cafe");
        let government_id = string::utf8(b"GOV124");
        let business_type = string::utf8(b"Cafe");
        let validity_years = 1;

        business_license::issue_license(
            admin,
            business_owner,
            license_id,
            business_name,
            government_id,
            business_type,
            validity_years
        );

        // Verify license is valid
        assert!(business_license::verify_license(license_id) == true, 6);
    }

    #[test(admin = @food_safety_contracts, aptos_framework = @0x1)]
    public fun test_verify_license_expired(admin: &signer, aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        business_license::init_module(admin);
        
        let business_owner = @0x123;
        let license_id = string::utf8(b"LIC003");
        let business_name = string::utf8(b"Test Bakery");
        let government_id = string::utf8(b"GOV125");
        let business_type = string::utf8(b"Bakery");
        let validity_years = 1;

        business_license::issue_license(
            admin,
            business_owner,
            license_id,
            business_name,
            government_id,
            business_type,
            validity_years
        );

        // Fast forward time to expire the license
        let future_time = timestamp::now_seconds() + (2 * 365 * 24 * 60 * 60); // 2 years
        timestamp::update_global_time_for_test(future_time);

        // Verify license is expired
        assert!(business_license::verify_license(license_id) == false, 7);
    }

    #[test(admin = @food_safety_contracts)]
    #[expected_failure(abort_code = 2, location = food_safety_contracts::business_license)]
    public fun test_get_license_by_id_not_found(admin: &signer) {
        business_license::init_module(admin);
        
        let non_existent_id = string::utf8(b"NONEXISTENT");
        let _ = business_license::get_license_by_id(non_existent_id);
    }

    #[test(admin = @food_safety_contracts)]
    public fun test_verify_license_not_found(admin: &signer) {
        business_license::init_module(admin);
        
        let non_existent_id = string::utf8(b"NONEXISTENT");
        assert!(business_license::verify_license(non_existent_id) == false, 8);
    }
}