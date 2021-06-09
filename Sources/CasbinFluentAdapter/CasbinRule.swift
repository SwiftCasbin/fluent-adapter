//
//  CasbinRule.swift
//  CasbinFluentAdapter
//
//  Created by 孟祥文 on 2021/6/9.
//

import Fluent
import Foundation

public final class  CasbinRule:Fluent.Model {
    public init(id: UUID? = nil, pType: String, v0: String, v1: String, v2: String, v3: String, v4: String, v5: String) {
        self.id = id
        self.pType = pType
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
        self.v5 = v5
    }
    
    public static var schema: String = "casbin_rule"
    public init() {}
    
    @ID()
    public var id: UUID?
    @Field(key: "p_type")
    public var pType:String
    @Field(key: "v0")
    public var v0:String
    @Field(key: "v1")
    public var v1:String
    @Field(key: "v2")
    public var v2:String
    @Field(key: "v3")
    public var v3:String
    @Field(key: "v4")
    public var v4:String
    @Field(key: "v5")
    public var v5: String
    
    
}

extension CasbinRule {
    public struct Migration :Fluent.Migration {
        public func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CasbinRule.schema)
                .id()
                .field("p_type", .string, .required)
                .field("v1", .string, .required)
                .field("v2", .string, .required)
                .field("v3", .string, .required)
                .field("v4", .string, .required)
                .field("v5", .string, .required)
                .create()
        }
        
        public func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CasbinRule.schema).delete()
        }
    }
}
