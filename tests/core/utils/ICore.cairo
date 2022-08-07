%lang starknet

@contract_interface
namespace ICore:
    func get_pool_contract_hash() -> (res: felt):
    end

    func get_salt() -> (res: felt):
    end

    func get_token_address() -> (res: felt):
    end

    func get_user_registrar() -> (res: felt):
    end

    func get_current_pool_id() -> (res: felt):
    end

    func get_pool_address(pool_id: felt) -> (res: felt):
    end

    func deploy_pool(
        vote_start_time_ : felt,
        vote_end_time_: felt,
        stream_start_time_ : felt,
        stream_end_time_: felt,
    ):
    end

    func add_buidl(
        ipfs_len: felt,
        ipfs: felt*,
    ):
    end
end