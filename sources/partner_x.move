module food_safety_contracts::partner_x {
    use std::signer;
    use std::string::String;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::event;

    struct PartnerXLicense has key, store {
        partner_id: String,
        partner_address: address,
        credentials: String,
        specialization: String,
        issue_date: u64,
        is_active: bool,
        verified_reports: u64,
    }

    struct ReportVerification has key, store {
        report_id: String,
        product_name: String,
        reporter_address: address,
        partner_address: address,
        verdict: String,
        evidence: String,
        timestamp: u64,
        is_final: bool,
    }

    struct PartnerRegistry has key {
        partners: vector<PartnerXLicense>,
        verifications: vector<ReportVerification>,
        total_partners: u64,
        total_verifications: u64,
    }

    #[event]
    struct PartnerLicenseIssued has drop, store {
        partner_id: String,
        partner_address: address,
        issue_date: u64,
    }

    #[event]
    struct ReportVerified has drop, store {
        report_id: String,
        partner_address: address,
        verdict: String,
        timestamp: u64,
    }

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_PARTNER_NOT_FOUND: u64 = 2;
    const E_REPORT_NOT_FOUND: u64 = 3;

    fun init_module(account: &signer) {
        let registry = PartnerRegistry {
            partners: vector::empty(),
            verifications: vector::empty(),
            total_partners: 0,
            total_verifications: 0,
        };
        move_to(account, registry);
    }

    public entry fun issue_partner_license(
        // admin: &signer,
        partner_address: address,
        partner_id: String,
        credentials: String,
        specialization: String,
    ) acquires PartnerRegistry {
        let current_time = timestamp::now_seconds();

        let license = PartnerXLicense {
            partner_id,
            partner_address,
            credentials,
            specialization,
            issue_date: current_time,
            is_active: true,
            verified_reports: 0,
        };

        let registry = borrow_global_mut<PartnerRegistry>(@food_safety_contracts);
        vector::push_back(&mut registry.partners, license);
        registry.total_partners = registry.total_partners + 1;

        event::emit(PartnerLicenseIssued {
            partner_id,
            partner_address,
            issue_date: current_time,
        });
    }

    public entry fun submit_verification(
        partner: &signer,
        report_id: String,
        product_name: String,
        reporter_address: address,
        verdict: String,
        evidence: String,
    ) acquires PartnerRegistry {
        let partner_addr = signer::address_of(partner);
        let current_time = timestamp::now_seconds();

        // Verify partner is authorized
        let registry = borrow_global_mut<PartnerRegistry>(@food_safety_contracts);
        let is_authorized = false;
        let len = vector::length(&registry.partners);
        let i = 0;
        
        while (i < len) {
            let partner_license = vector::borrow_mut(&mut registry.partners, i);
            if (partner_license.partner_address == partner_addr && partner_license.is_active) {
                is_authorized = true;
                partner_license.verified_reports = partner_license.verified_reports + 1;
                break
            };
            i = i + 1;
        };

        assert!(is_authorized, E_NOT_AUTHORIZED);

        let verification = ReportVerification {
            report_id,
            product_name,
            reporter_address,
            partner_address: partner_addr,
            verdict,
            evidence,
            timestamp: current_time,
            is_final: true,
        };

        vector::push_back(&mut registry.verifications, verification);
        registry.total_verifications = registry.total_verifications + 1;

        event::emit(ReportVerified {
            report_id,
            partner_address: partner_addr,
            verdict,
            timestamp: current_time,
        });
    }

    #[view]
    public fun get_verification_by_report_id(report_id: String): (String, String, address, String, u64) acquires PartnerRegistry {
        let registry = borrow_global<PartnerRegistry>(@food_safety_contracts);
        let len = vector::length(&registry.verifications);
        let i = 0;
        
        while (i < len) {
            let verification = vector::borrow(&registry.verifications, i);
            if (verification.report_id == report_id) {
                return (
                    verification.product_name,
                    verification.verdict,
                    verification.partner_address,
                    verification.evidence,
                    verification.timestamp
                )
            };
            i = i + 1;
        };
        
        abort E_REPORT_NOT_FOUND
    }

    #[view]
    public fun verify_partner(partner_address: address): bool acquires PartnerRegistry {
        let registry = borrow_global<PartnerRegistry>(@food_safety_contracts);
        let len = vector::length(&registry.partners);
        let i = 0;
        
        while (i < len) {
            let partner = vector::borrow(&registry.partners, i);
            if (partner.partner_address == partner_address) {
                return partner.is_active
            };
            i = i + 1;
        };
        
        false
    }
}