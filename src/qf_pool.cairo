%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le, assert_not_zero
from starkware.starknet.common.syscalls import get_contract_address, get_block_timestamp
from starkware.cairo.common.uint256 import (Uint256, uint256_eq, uint256_sub, uint256_mul, 
                                            uint256_sqrt, uint256_add,uint256_unsigned_div_rem,
                                            uint256_le,uint256_lt)
from starkware.cairo.common.alloc import alloc
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from structs.project_struct import ProjectInfo, ProjectVote, ProjectAccumulator, ProjectVerification, ProjectReturn

@storage_var
func erc20_addr() -> (addr: felt):
end

@storage_var
func initalized_matched_value() -> (is_init: felt):
end

# this is the current project id that will be used, after that it will get incremented
@storage_var
func current_project_id() -> (next: felt):
end

@storage_var
func project_info(project_id: felt) -> (info: ProjectInfo):
end

@storage_var
func reverse_user_project_id(owner: felt) -> (project_id: felt):
end

@storage_var
func project_ipfs_link(project_id: felt, index: felt) -> (link_partial: felt):
end

@storage_var
func vote_start_time() -> (time: felt):
end

@storage_var
func vote_end_time() -> (time: felt):
end

@storage_var
func stream_start_time() -> (time: felt):
end

@storage_var
func stream_end_time() -> (time: felt):
end

@storage_var
func claimed(project_id: felt) -> (claimed_amount: Uint256):
end

@storage_var
func project_vote(project_id: felt, voter_addr: felt) -> (vote: ProjectVote):
end

@storage_var
func project_accumulator(project_id: felt) -> (accumulator: ProjectAccumulator):
end

@storage_var
func total_project_contributed_fund() -> (total_contributed: Uint256):
end

@storage_var
func total_divisor() -> (total_divisor: Uint256):
end

@storage_var
func total_match() -> (fund: Uint256):
end

# submission storage
@storage_var
func project_verification(project_id: felt) -> (verification: ProjectVerification):
end

@storage_var
func project_verification_ipfs(project_id: felt, index: felt) -> (res: felt):
end

@event
func project_verification_submission(
    project_id : felt
):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    _erc20_addr: felt,
    core_contract_addr: felt,
    _vote_start_time: felt,
    _vote_end_time: felt,
    _stream_start_time: felt,
    _stream_end_time: felt
):
    erc20_addr.write(_erc20_addr)
    Ownable.initializer(core_contract_addr)
    vote_start_time.write(_vote_start_time)
    vote_end_time.write(_vote_end_time)
    stream_start_time.write(_stream_start_time)
    stream_end_time.write(_stream_end_time)
    current_project_id.write(1) # start from id = 1

    return ()
end

@view
func get_current_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (id:felt):
    let (res) = current_project_id.read()
    return (id=res)
end

@view 
func get_project_by_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: ProjectReturn):

    let (info) = project_info.read(project_id)
    let (accumulator) = project_accumulator.read(project_id)
    let (verification) = project_verification.read(project_id)

    let res = ProjectReturn(
                info.ipfs_link_len,
                info.owner,
                accumulator.sum_c, 
                accumulator.sum_c_sqrt,
                accumulator.square_sum_c_sqrt,
                verification.submission_ipfs_link_len,
                verification.admin_latest_approved_percentage,
                verification.is_approved_latest_submission
                )
    return (res=res)
end

@view 
func get_all_projects{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (res_len: felt, res: ProjectReturn*):

    let (current_id) = current_project_id.read() # need to -1 to get the length
    let (project_return: ProjectReturn*) = alloc()
    let (res_len, res) = get_all_projects_internal(0, current_id-1, 0, project_return)
    return (res_len, res)
end


func get_all_projects_internal{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
    current_index: felt, 
    total_length: felt, 
    res_len: felt, 
    res: ProjectReturn*
    ) -> (res_len: felt, res: ProjectReturn*):

    if total_length == 0: 
        return (res_len=res_len, res=res)
    end

    let (info) = project_info.read(current_index+1)
    let (accumulator) = project_accumulator.read(current_index+1)
    let (verification) = project_verification.read(current_index+1)

    assert res[current_index].ipfs_link_len = info.ipfs_link_len
    assert res[current_index].owner = info.owner
    assert res[current_index].sum_c = accumulator.sum_c
    assert res[current_index].sum_c_sqrt = accumulator.sum_c_sqrt
    assert res[current_index].square_sum_c_sqrt = accumulator.square_sum_c_sqrt
    assert res[current_index].submission_ipfs_link_len = verification.submission_ipfs_link_len
    assert res[current_index].admin_latest_approved_percentage = verification.admin_latest_approved_percentage
    assert res[current_index].is_approved_latest_submission = verification.is_approved_latest_submission

    let (res_len, res) = get_all_projects_internal(current_index+1, total_length-1, res_len+1, res)

    return (res_len, res)
end

@view
func get_erc20_addr{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (addr:felt):
    let (res) = erc20_addr.read()
    return (addr=res)
end

@view
func get_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (owner:felt):
    let (res) = Ownable.owner()
    return (owner=res)
end

@view
func get_project_vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, voter_addr: felt) -> (res: ProjectVote):
    let (res) = project_vote.read(project_id=project_id, voter_addr=voter_addr)
    return (res=res)
end

@view
func get_project_accumulator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: ProjectAccumulator):
    let (res) = project_accumulator.read(project_id=project_id)
    return (res=res)
end

@view
func get_total_project_contributed_fund{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (total: Uint256):

    let (res) = total_project_contributed_fund.read()
    return (total=res)
end

@view
func get_total_match{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (matched: Uint256):

        let (res) = total_match.read()
        return (matched=res)
    end

@view
func get_total_divisor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (res: Uint256):
    let (res) = total_divisor.read()
    return (res=res)
end

@view
func get_vote_start_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (time: felt):
    let (res) = vote_start_time.read()
    return (time=res)
end

@view
func get_vote_end_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = vote_end_time.read()
    return (time=res)
end

@view
func get_stream_start_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = stream_start_time.read()
    return (time=res)
end

@view
func get_stream_end_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = stream_end_time.read()
    return (time=res)
end

@view
func get_claimed_amount_by_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(project_id: felt) -> (amount: Uint256):
    let (res) = claimed.read(project_id=project_id)
    return (amount=res)
end

@view
func get_project_verification{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(project_id: felt) -> (res: ProjectVerification):
    let (res) = project_verification.read(project_id=project_id)
    return (res=res)
end

@view
func get_project_verification_ipfs{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):

    if ipfs_len == 0:
        return (ipfs_res_link_len=link_len, ipfs_res_link=link)
    end

    let (ipfs_index_link) = project_verification_ipfs.read(project_id=project_id, index=current_index)
    assert [link + current_index] = ipfs_index_link

    let (len, ipfs_link) = get_project_verification_ipfs(
                                                    project_id=project_id, 
                                                    current_index=current_index+1,
                                                    ipfs_len=ipfs_len-1,
                                                    link_len=link_len+1,
                                                    link=link
                                                )
                      
    return (ipfs_res_link_len=len, ipfs_res_link=ipfs_link)  
end

# flow:
# deploy this contract, transfer erc20 to this contract, set matched value
@external
func init_matched_pool{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}():
    Ownable.assert_only_owner()

    with_attr error_message("Has been initialized"):
        let (is_init) = initalized_matched_value.read()
        assert is_init = 0
    end

    let (erc20) = erc20_addr.read()
    let (contract_address) = get_contract_address()
    let (balance) = IERC20.balanceOf(contract_address=erc20, account=contract_address)

    total_match.write(balance)
    initalized_matched_value.write(1)

    return ()
end

@external
func add_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
      owner: felt, 
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ) -> (project_id: felt) :
    alloc_locals
    # allows project to be added at any time
    # we wont be checking for duplicates ipfs_link

    # check if owner has created a pool before
    with_attr error_message("Owner already has a project in the current pool"):
            let (pool_id) = reverse_user_project_id.read(owner)
            assert pool_id = 0
     end

    let info = ProjectInfo(ipfs_link_len=ipfs_link_len, owner=owner)
    let (current_id) = current_project_id.read()
    local current_id = current_id
    current_project_id.write(current_id + 1)

    project_info.write(project_id=current_id, value=info)
    reverse_user_project_id.write(owner, current_id)
    store_ipfs_link(project_id=current_id, current_index=0, ipfs_link_len=ipfs_link_len, ipfs_link=ipfs_link)
    return(project_id=current_id)
end

func store_ipfs_link{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
      project_id: felt,
      current_index: felt,
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    if ipfs_link_len == 0:
        return ()
    end

    project_ipfs_link.write(project_id=project_id, index=current_index, value=ipfs_link[0])
    store_ipfs_link(
                    project_id=project_id, 
                    current_index=current_index+1, 
                    ipfs_link_len=ipfs_link_len-1, 
                    ipfs_link=&ipfs_link[1]
                )

    return ()
end

@view
func get_project_info{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: ProjectInfo):
    let (res) = project_info.read(project_id)
    return (res=res)
end

@view 
func get_reverse_user_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(owner:felt) -> (project_id: felt):
    let (res) = reverse_user_project_id.read(owner)

    return (project_id=res)
end

@view
func get_project_ipfs_link{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):

    if ipfs_len == 0:
        return (ipfs_res_link_len=link_len, ipfs_res_link=link)
    end

    let (ipfs_index_link) = project_ipfs_link.read(project_id=project_id, index=current_index)
    assert [link + current_index] = ipfs_index_link

    let (len, ipfs_link) = get_project_ipfs_link(
                                                    project_id=project_id, 
                                                    current_index=current_index+1,
                                                    ipfs_len=ipfs_len-1,
                                                    link_len=link_len+1,
                                                    link=link
                                                )
                      
    return (ipfs_res_link_len=len, ipfs_res_link=ipfs_link)                          
end

# callable only by core_contract
# core_contract will transfer erc20 donated to pool
# and call this function
@external
func vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, amount: Uint256, voter_addr: felt):
    alloc_locals
    local c_prev: Uint256

    Ownable.assert_only_owner()
    assert_only_within_voting_period()
    assert_project_exist(project_id)

    let (current_project_accumulator) = project_accumulator.read(project_id=project_id)
    let (is_sum_c_sqrt_is_0) = uint256_eq(current_project_accumulator.square_sum_c_sqrt, Uint256(0,0))
    if is_sum_c_sqrt_is_0 == 0:
        let (current_total_divisor) = total_divisor.read()
        let (total_divisor_removed) = uint256_sub(current_total_divisor, current_project_accumulator.square_sum_c_sqrt)
        total_divisor.write(total_divisor_removed)

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end


    # get current ProjectVote
    let (current_project_vote) = project_vote.read(project_id=project_id, voter_addr=voter_addr)
    let (is_c_zero) = uint256_eq(current_project_vote.c, Uint256(0,0))
    if is_c_zero == 0:
        c_prev.low = current_project_vote.c.low
        c_prev.high = current_project_vote.c.high

        let (current_project_accumulator) = project_accumulator.read(project_id=project_id)
        let (sum_c_sqrt_removed) = uint256_sub(current_project_accumulator.sum_c_sqrt, current_project_vote.c_sqrt)
        let (square_sum_c_sqrt_removed, mul_carry) = uint256_mul(sum_c_sqrt_removed, sum_c_sqrt_removed)
        assert mul_carry = Uint256(0,0)

        project_accumulator.write(
                    project_id=project_id, 
                    value=ProjectAccumulator(
                                current_project_accumulator.sum_c,
                                sum_c_sqrt_removed,
                                square_sum_c_sqrt_removed
                                )
                    )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        c_prev.low = 0
        c_prev.high = 0

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let (current_project_accumulator) = project_accumulator.read(project_id=project_id)

    # project vote
    let (new_c, add_carry) = uint256_add(amount, c_prev)
    assert add_carry = 0

    let (new_c_sqrt) = uint256_sqrt(new_c)

    let new_project_vote = ProjectVote(c=new_c, c_sqrt=new_c_sqrt)
    project_vote.write(project_id=project_id, voter_addr=voter_addr, value=new_project_vote)

    # project accumulator
    let (new_sum_c, add_carry) = uint256_add(current_project_accumulator.sum_c, amount)
    assert add_carry = 0

    let (new_sum_c_sqrt, add_carry) = uint256_add(current_project_accumulator.sum_c_sqrt, new_c_sqrt)
    assert add_carry = 0

    let (new_square_sum_c_sqrt, mul_carry) = uint256_mul(new_sum_c_sqrt, new_sum_c_sqrt)
    assert mul_carry = Uint256(0,0)

    project_accumulator.write(project_id=project_id, value=ProjectAccumulator(new_sum_c, new_sum_c_sqrt, new_square_sum_c_sqrt))

    # total divisor
    let (current_total_divisor) = total_divisor.read()
    let (new_total_divisor, add_carry) = uint256_add(current_total_divisor, new_square_sum_c_sqrt)
    assert add_carry = 0
    total_divisor.write(new_total_divisor)

    # total project contributed fund
    let (current_total_project_contributed_fund) = total_project_contributed_fund.read()
    let (new_total_project_contributed_fund, add_carry) = uint256_add(current_total_project_contributed_fund, amount)
    assert add_carry = 0
    total_project_contributed_fund.write(new_total_project_contributed_fund)

    return ()
end

func assert_project_exist{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt):

     with_attr error_message("Project id cannot be zero"):
            assert_not_zero(project_id)
     end

     with_attr error_message("Project does not exist"):
            let (current_id) = current_project_id.read()
            assert_lt(project_id, current_id)
     end

    return ()
end

func assert_only_within_voting_period{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

     let (timestamp) = get_block_timestamp()

     with_attr error_message("Cannot vote before vote time"):
            let (start_time) = vote_start_time.read()
            assert_le(start_time, timestamp)
     end

     with_attr error_message("Cannot vote after vote time"):
            let (end_time) = vote_end_time.read()
            assert_le(timestamp, end_time)
     end

     return ()
end

# function callable by core contract only
@external
func submit_work_proof{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_owner: felt, ipfs_len: felt, ipfs: felt*):
    alloc_locals

    Ownable.assert_only_owner()

    # check project id exist for the owner
    let (id) = reverse_user_project_id.read(project_owner)
    local id = id

    with_attr error_message("Owner has no project"):
           assert_not_zero(id)
    end

    let (previous_project_verification) = project_verification.read(project_id=id)
    # update ipfs_len
    # set is_approved_latest_submission to 0
    let new_project_verification = ProjectVerification(ipfs_len, previous_project_verification.admin_latest_approved_percentage, 0)
    project_verification.write(project_id=id, value=new_project_verification)

    # set ipfs
    store_submission_ipfs(project_id=id, current_index=0, ipfs_link_len=ipfs_len, ipfs_link=ipfs)

    # we can emit event in case we want to alert admin (not in hackathon)
    project_verification_submission.emit(project_id=id)
    return ()
end

func store_submission_ipfs{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
      project_id: felt,
      current_index: felt,
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    if ipfs_link_len == 0:
        return ()
    end

    project_verification_ipfs.write(project_id=project_id, index=current_index, value=ipfs_link[0])
    store_submission_ipfs(
                    project_id=project_id, 
                    current_index=current_index+1, 
                    ipfs_link_len=ipfs_link_len-1, 
                    ipfs_link=&ipfs_link[1]
                )

    return ()
end

# checking of admin is done in core contract
@external 
func admin_verify_work{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, approved_percentage: felt):

    Ownable.assert_only_owner()

    # check approved_percentage between 0 and 100
    assert_percentage_within_range(val=approved_percentage)
    assert_project_exist(project_id)

    let (previous_project_verification) = project_verification.read(project_id=project_id)
    # check approved percentage greater than previously approved
    # we might not need this function atm
    # with_attr error_message("Approved percentage must be greater than previously approved"):
    #     let (is_greater_than_previous) = assert_lt(previous_project_verification, approved_percentage)
    # end

    # update if everything is satisfied
    let new_project_verification = ProjectVerification(previous_project_verification.submission_ipfs_link_len, approved_percentage, 1)
    project_verification.write(project_id=project_id, value=new_project_verification)

    return ()
end

func assert_percentage_within_range{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(val:felt):

    with_attr error_message("Percentage not within range"):
        assert_le(0, val)

        assert_le(val, 100)
    end

    return ()
end 

# anyone can call this function,
# the reward will to the project_owner
@external
func claim{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_owner: felt):
    alloc_locals

    let (project_id) = reverse_user_project_id.read(project_owner)

     with_attr error_message("Owner has no project"):
            assert_not_zero(project_id)
     end

    # get percentage approved
    let (verification) = project_verification.read(project_id=project_id)

    # total_matched
    let (matched) = get_matched_for_project(project_id=project_id)
    let (accumulator) = get_project_accumulator(project_id=project_id)
    let (total_fund, add_carry) = uint256_add(matched, accumulator.sum_c)
    assert add_carry = 0

    # find current streamed amount
    let (start_time) = stream_start_time.read()
    let (end_time) = stream_end_time.read()
    let (streamed_percentage) = get_time_as_percentage(start_time=start_time, end_time=end_time)

    let (streamed_amount_temp, mul_carry) =  uint256_mul(total_fund, streamed_percentage)
    assert mul_carry = Uint256(0,0)

    let MULTIPLIER_1_E_20 = Uint256(0x56bc75e2d63100000, 0)
    let (streamed_amount, _) = uint256_unsigned_div_rem(streamed_amount_temp, MULTIPLIER_1_E_20)

    # admin approved amount =  total matched * percentage approved
    let admin_approved_percentage_uint256 = Uint256(verification.admin_latest_approved_percentage, 0)
    let (temp, mul_carry) = uint256_mul(total_fund, admin_approved_percentage_uint256)
    assert mul_carry = Uint256(0,0)
    let (admin_approved_amount, _) = uint256_unsigned_div_rem(temp, Uint256(2,0))

    local raw_claim_amount: Uint256
    let (is_approved_gt_stream) = uint256_le(streamed_amount, admin_approved_amount)
    # if approved amount > stream amount, we use stream amount as raw_claim_amount
    if is_approved_gt_stream == 1:
        raw_claim_amount.low = streamed_amount.low
        raw_claim_amount.high = streamed_amount.high
    else:
        # else we use approve amount as raw_claim_amount
        raw_claim_amount.low = admin_approved_amount.low
        raw_claim_amount.high = admin_approved_amount.high
    end

    # get previous claimed amount from storage
    let (previous_claimed) = claimed.read(project_id=project_id)

    # claimed_amount = raw_claim_amount - claimed
    let (to_claim) = uint256_sub(raw_claim_amount, previous_claimed)

    # update claimed to store new raw_claim_amount
    claimed.write(project_id=project_id, value=to_claim)

    # send claimed_amount to user
    let (erc20) = erc20_addr.read()
    IERC20.transfer(contract_address=erc20, recipient=project_owner, amount=to_claim)

    return ()
end

@view
func get_matched_for_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: Uint256):

    alloc_locals
    local syscall_ptr_temp: felt* = syscall_ptr

    let (accumulator) = project_accumulator.read(project_id=project_id)
    let (match) = total_match.read()
    let (divisor) = total_divisor.read()

    # assert_not_zero(total_divisor)

    let (res_temp, mul_carry) = uint256_mul(accumulator.square_sum_c_sqrt, match)
    assert mul_carry = Uint256(0, 0)

    let (res, _) = uint256_unsigned_div_rem(res_temp, divisor)

    return (res=res)
end

@view
func get_time_as_percentage2{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (res: Uint256):
    alloc_locals
    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    let MULTIPLIER_1_E_20 = Uint256(0x56bc75e2d63100000, 0)

    let (current_time) = get_block_timestamp()
    let current_time_uint256 = Uint256(current_time,0)

    let (end_time) = stream_end_time.read()
    let end_time_uint256 = Uint256(end_time,0)
    let (is_current_time_greater_than_end) = uint256_lt(end_time_uint256, current_time_uint256)
    # if current time > stream end time, 100%
    if is_current_time_greater_than_end == 1:
        let percentage = Uint256(100,0)
        let (res, mul_carry) = uint256_mul(percentage, MULTIPLIER_1_E_20)
        assert mul_carry = Uint256(0,0)
        return (res=res)
    end

    let (start_time) = stream_start_time.read()
    let start_time_uint256 = Uint256(start_time,0)
    let (is_start_time_less_than_current) = uint256_lt(start_time_uint256, current_time_uint256)
    # if stream start time < current  time, 0%
    if is_start_time_less_than_current == 1:
        return (res=Uint256(0,0))
    end

    # numerator = get_block_timestamp() - stream_start_time
    let (numerator) = uint256_sub(current_time_uint256, start_time_uint256)
    # denominator = stream_end_time - stream_start_time
    let (denominator) = uint256_sub(end_time_uint256, start_time_uint256)

    let (temp, mul_carry) = uint256_mul(numerator, MULTIPLIER_1_E_20)
    assert mul_carry = Uint256(0,0)

    # % = numerator * 1e20 / divisor
    # if result is 1e20, it is 1%
    let (res, _) = uint256_unsigned_div_rem(temp, denominator)
    return (res=res)
end

@view
func get_time_as_percentage{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(start_time: felt, end_time: felt) -> (res: Uint256):
    alloc_locals
    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    let MULTIPLIER_1_E_20 = Uint256(0x56bc75e2d63100000, 0)

    let (current_time) = get_block_timestamp()
    let current_time_uint256 = Uint256(current_time,0)

    let end_time_uint256 = Uint256(end_time,0)
    let (is_current_time_greater_than_end) = uint256_lt(end_time_uint256, current_time_uint256)
    # if current time > stream end time, 100%
    if is_current_time_greater_than_end == 1:
        let percentage = Uint256(100,0)
        let (res, mul_carry) = uint256_mul(percentage, MULTIPLIER_1_E_20)
        assert mul_carry = Uint256(0,0)
        return (res=res)
    end

    let start_time_uint256 = Uint256(start_time,0)
    let (is_start_time_less_than_current) = uint256_lt(current_time_uint256, start_time_uint256)
    # if stream start time < current  time, 0%
    if is_start_time_less_than_current == 1:
        return (res=Uint256(0,0))
    end

    let diff = current_time - start_time
    let numerator = Uint256(diff, 0)

    let diff = end_time - start_time
    let denominator = Uint256(diff, 0)

    let (temp, mul_carry) = uint256_mul(numerator, MULTIPLIER_1_E_20)
    assert mul_carry = Uint256(0,0)

    let (res, _) = uint256_unsigned_div_rem(temp, denominator)
    return (res=res)
end