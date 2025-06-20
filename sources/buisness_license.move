module food_safety_contracts::business_license {
    use std::signer;
    use std::string::String;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::event;

    struct BusinessLicense has key, store {
        license_id: String,
        business_name: String,
        owner_address: address,
        government_id: String,
        business_type: String,
        issue_date: u64,
        expiry_date: u64,
        is_active: bool,
        approved_by: address,
    }

    struct LicenseRegistry has key {
        licenses: vector<BusinessLicense>,
        total_licenses: u64,
    }

    #[event]
    struct LicenseIssued has drop, store {
        license_id: String,
        business_name: String,
        owner_address: address,
        issue_date: u64,
    }

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_LICENSE_NOT_FOUND: u64 = 2;
    const E_INVALID_EXPIRY_DATE: u64 = 3;

    fun init_module(account: &signer) {
        let registry = LicenseRegistry {
            licenses: vector::empty(),
            total_licenses: 0,
        };
        move_to(account, registry);
    }

    // Add authorization check for registry creation
    public fun create_registry(account: &signer) {
        // Only allow the contract owner to create registry
        assert!(signer::address_of(account) == @food_safety_contracts, E_NOT_AUTHORIZED);
        init_module(account);
    }

    // Add this view function to check if registry exists
    #[view]
    public fun registry_exists(account_addr: address): bool {
        exists<LicenseRegistry>(account_addr)
    }

    public entry fun issue_license(
        admin: &signer, // our account that issues the license
        business_owner: address,
        license_id: String,
        business_name: String,
        government_id: String,
        business_type: String,
        validity_years: u64,
    ) acquires LicenseRegistry {
        let admin_addr = signer::address_of(admin);
        
        // Add authorization check
        assert!(admin_addr == @food_safety_contracts, E_NOT_AUTHORIZED);
        
        // Add validity check for years
        assert!(validity_years > 0, E_INVALID_EXPIRY_DATE);
        
        let current_time = timestamp::now_seconds();
        let expiry_date = current_time + (validity_years * 365 * 24 * 60 * 60);

        let license = BusinessLicense {
            license_id,
            business_name,
            owner_address: business_owner,
            government_id,
            business_type,
            issue_date: current_time,
            expiry_date,
            is_active: true,
            approved_by: admin_addr,
        };

        let registry = borrow_global_mut<LicenseRegistry>(@food_safety_contracts);
        vector::push_back(&mut registry.licenses, license);
        registry.total_licenses = registry.total_licenses + 1;

        event::emit(LicenseIssued {
            license_id,
            business_name,
            owner_address: business_owner,
            issue_date: current_time,
        });
    }

    #[view]
    public fun get_license_by_id(license_id: String): (String, String, address, bool) acquires LicenseRegistry {
        let registry = borrow_global<LicenseRegistry>(@food_safety_contracts);
        let len = vector::length(&registry.licenses);
        let i = 0;
        
        while (i < len) {
            let license = vector::borrow(&registry.licenses, i);
            if (license.license_id == license_id) {
                return (license.business_name, license.business_type, license.owner_address, license.is_active)
            };
            i = i + 1;
        };
        
        abort E_LICENSE_NOT_FOUND
    }

    #[view]
    public fun verify_license(license_id: String): bool acquires LicenseRegistry {
        // Check if registry exists first
        if (!exists<LicenseRegistry>(@food_safety_contracts)) {
            return false
        };
        
        let registry = borrow_global<LicenseRegistry>(@food_safety_contracts);
        let len = vector::length(&registry.licenses);
        let i = 0;
        let current_time = timestamp::now_seconds();
        
        while (i < len) {
            let license = vector::borrow(&registry.licenses, i);
            if (license.license_id == license_id) {
                return (license.is_active && license.expiry_date > current_time)
            };
            i = i + 1;
        };
        
        false
    }
}