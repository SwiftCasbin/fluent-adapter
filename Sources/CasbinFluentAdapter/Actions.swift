

import Fluent

struct Actions {
   static func removePolicy(db:Database,ptype:String,rule:[String]) -> EventLoopFuture<Void> {
        let rule = normalizeCasbinRule(rule, 0)
        let filter = CasbinRule.query(on: db)
            .filter(\.$pType == ptype)
            .filter(\.$v0 == rule[0])
            .filter(\.$v1 == rule[1])
            .filter(\.$v2 == rule[2])
            .filter(\.$v3 == rule[3])
            .filter(\.$v4 == rule[4])
            .filter(\.$v5 == rule[5])
        return filter.delete(force: true)
    }
   static func removePolicies(db:Database,ptype:String,rules:[[String]]) -> EventLoopFuture<Void> {
        db.transaction { _db in
            _db.eventLoop.flatten(
                rules.map { removePolicy(db: _db, ptype: ptype, rule: $0)}
            )
        }
    }
   static func removeFilteredPolicy(db:Database,ptype:String,fieldIndex:Int,fieldValues:[String]) -> EventLoopFuture<Void> {
        let fieldValues = normalizeCasbinRule(fieldValues, fieldIndex)
        let query = CasbinRule.query(on: db).filter(\.$pType == ptype)
        switch fieldIndex {
        case 5:
             query.filter(\.$v5 == fieldValues[0])
        case 4:
            query.filter(\.$v4 == fieldValues[0])
                .filter(\.$v5 == fieldValues[1])
        case 3:
            query.filter(\.$v3 == fieldValues[0])
                .filter(\.$v4 == fieldValues[1])
                .filter(\.$v5 == fieldValues[2])
        case 2:
            query.filter(\.$v2 == fieldValues[0])
                .filter(\.$v3 == fieldValues[1])
                .filter(\.$v4 == fieldValues[2])
                .filter(\.$v5 == fieldValues[3])
        case 1:
            query.filter(\.$v1 == fieldValues[0])
                .filter(\.$v2 == fieldValues[1])
                .filter(\.$v3 == fieldValues[2])
                .filter(\.$v4 == fieldValues[3])
                .filter(\.$v5 == fieldValues[4])
        default:
            query.filter(\.$v0 == fieldValues[0])
                .filter(\.$v1 == fieldValues[1])
                .filter(\.$v2 == fieldValues[2])
                .filter(\.$v3 == fieldValues[3])
                .filter(\.$v4 == fieldValues[4])
                .filter(\.$v5 == fieldValues[5])
        }
        return query.delete(force: true)
    }
   static func clearPolicy(db:Database) -> EventLoopFuture<Void> {
        CasbinRule.query(on: db).delete(force: true)
    }
   static func savePolicy(db:Database,rules: [CasbinRule]) -> EventLoopFuture<Void> {
        rules.create(on: db)
    }
   static func loadPolicy(db:Database) -> EventLoopFuture<[CasbinRule]> {
        CasbinRule.query(on: db).all()
    }
   static func addPolicy(db:Database,rule:CasbinRule) -> EventLoopFuture<Void> {
         rule.create(on: db)
    }
    
   static func normalizeCasbinRule(_ rule:[String],_ fieldIndex:Int) -> [String] {
        var rule = rule
        let len = 6 - fieldIndex
        if rule.count < len {
            rule.append(contentsOf: Array<String>(repeating: "", count: len - rule.count))
        } else {
            rule  = Array(rule[..<len])
        }
        return rule
    }
}
