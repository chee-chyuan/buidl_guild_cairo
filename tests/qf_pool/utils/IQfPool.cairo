%lang starknet
from starkware.cairo.common.uint256 import Uint256
from src.structs.project_struct import ProjectInfo, ProjectAccumulator, ProjectVote, ProjectVerification

@contract_interface
namespace IQfPool:

    func get_current_project_id() -> (res: felt):
    end

    func get_erc20_addr() -> (res: felt):
    end

    func get_owner() -> (res: felt):
    end

    func get_project_vote(project_id: felt, voter_addr: felt) -> (res: ProjectVote):
    end

    func get_project_accumulator(project_id: felt) -> (res: ProjectAccumulator):
    end

    func get_total_project_contributed_fund() -> (res: Uint256):
    end

    func get_total_match() -> (res: Uint256):
    end

    func get_vote_start_time() -> (res: felt):
    end

    func get_vote_end_time() -> (res: felt):
    end

    func get_stream_start_time() -> (res: felt):
    end

    func get_stream_end_time() -> (res: felt):
    end

    func get_claimed_amount_by_project(project_id: felt) -> (res: Uint256):
    end

    func get_project_verification(project_id: felt) -> (res: ProjectVerification):
    end

    func get_project_verification_ipfs(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):
    end

    func init_matched_pool():
    end

    func add_project(
        owner: felt, 
        ipfs_link_len: felt, 
        ipfs_link: felt*
    ):
    end

    func get_project_info(project_id: felt) -> (res: ProjectInfo):
    end

    func get_reverse_user_project_id(owner:felt) -> (project_id: felt):
    end

    func get_project_ipfs_link(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):
    end

    func vote(project_id: felt, amount: Uint256, voter_addr: felt):
    end

    func submit_work_proof(project_owner: felt, ipfs_len: felt, ipfs: felt*):
    end
end
