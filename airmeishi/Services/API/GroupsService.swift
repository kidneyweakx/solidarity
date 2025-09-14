//
//  GroupsService.swift
//  airmeishi
//
//  Group management endpoints
//

import Foundation

class GroupsService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    /// POST /group
    func createGroup(_ payload: CreateGroupRequest) async -> CardResult<CreateGroupResponse> {
        return await client.request(
            path: "group",
            method: .POST,
            body: payload,
            decodeAs: CreateGroupResponse.self
        )
    }
    
    /// POST /group/{name}/member
    func addMember(groupName: String, payload: AddGroupMemberRequest) async -> CardResult<AddGroupMemberResponse> {
        return await client.request(
            path: "group/\(groupName)/member",
            method: .POST,
            body: payload,
            decodeAs: AddGroupMemberResponse.self
        )
    }
}


