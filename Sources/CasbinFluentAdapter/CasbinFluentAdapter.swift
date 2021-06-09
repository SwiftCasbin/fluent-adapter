
import Fluent
import Casbin

public final class FluentAdapter {
    public init(database: Database) {
        self.database = database
    }
    
    public var isFiltered:Bool = false
    
    public var database: Database
    
    func savePolicyLine(ptype:String,rule:[String]) -> CasbinRule? {
        if ptype.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || rule.isEmpty {
            return nil
        }
        let newRule = CasbinRule.init()
        newRule.pType = ptype
        
        newRule.v0 = rule[0]
        if rule.count > 1 {
            newRule.v1 = rule[1]
        }
        if rule.count > 2 {
            newRule.v2 = rule[3]
        }
        if rule.count > 3 {
            newRule.v3 = rule[3]
        }
        if rule.count > 4 {
            newRule.v4 = rule[4]
        }
        if rule.count > 5 {
            newRule.v5 = rule[5]
        }
        return newRule
    }
    func loadPolicyLine(rule: CasbinRule) -> [String]? {
        if rule.pType.first != nil {
            return normalizePolicy(rule: rule)
        }
        return nil
    }
    func loadFilteredPolicyLine(rule:CasbinRule,f:Filter) ->(Bool,[String])?  {
        if let sec = rule.pType.first {
            if let policy = normalizePolicy(rule: rule) {
                var isFiltered = true
                if sec == "p" {
                    for (i,r) in f.p.enumerated() {
                        if !r.isEmpty && r != policy[i] {
                            isFiltered = false
                        }
                    }
                } else if sec == "g" {
                    for (i,r) in f.g.enumerated() {
                        if !r.isEmpty && r != policy[i] {
                            isFiltered = false
                        }
                    }
                } else {
                    return nil
                }
                return (isFiltered,policy)
            }
        }
        return nil
    }
    
    func normalizePolicy(rule:CasbinRule) -> [String]? {
        var result = [rule.v0,rule.v1,rule.v2,rule.v3,rule.v4,rule.v5]
        while result.last != nil {
            if result.last!.isEmpty {
               result = result.dropLast()
            } else {
                break
            }
        }
        if !result.isEmpty {
            return result
        }
        return nil
    }
    
}

extension FluentAdapter: Adapter {
    public var eventloop: EventLoop {
        database.eventLoop
    }
    
    public func loadPolicy(m:Casbin.Model) -> EventLoopFuture<Void> {
        Actions.loadPolicy(db: database).map { rules in
            for casbinRule in rules {
                let rule = self.loadPolicyLine(rule: casbinRule)
                if let sec = casbinRule.pType.first {
                    if let ast = m.getModel()[String(sec)]?[casbinRule.pType] {
                        if let rule = rule {
                            ast.policy.append(rule)
                        }
                    }
                }
            }
        }
    }
    
    public func loadFilteredPolicy(m: Casbin.Model, f: Filter) -> EventLoopFuture<Void> {
        Actions.loadPolicy(db: database).map { rules in
            for casbinRule in rules {
                let rule = self.loadFilteredPolicyLine(rule: casbinRule, f: f)
                if let (isFiltered,rule) = rule {
                    if isFiltered {
                        self.isFiltered = isFiltered
                        if let sec = casbinRule.pType.first {
                            if let ast = m.getModel()[String(sec)]?[casbinRule.pType] {
                                ast.policy.append(rule)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func savePolicy(m: Casbin.Model) -> EventLoopFuture<Void> {
        var rules:[CasbinRule] = []
        if let astMap = m.getModel()["p"] {
            for (ptype,ast) in astMap {
                let newRules = ast.policy.compactMap {
                    savePolicyLine(ptype: ptype, rule: $0)
                }
                rules.append(contentsOf: newRules)
            }
        }
        if let astMap = m.getModel()["g"] {
            for (ptype,ast) in astMap {
                let newRules = ast.policy.compactMap {
                    savePolicyLine(ptype: ptype, rule: $0)
                }
                rules.append(contentsOf: newRules)
            }
        }
        return Actions.savePolicy(db: database, rules: rules)
    }
    
    public func clearPolicy() -> EventLoopFuture<Void> {
        Actions.clearPolicy(db: database)
    }
    
    public func addPolicy(sec: String, ptype: String, rule: [String]) -> EventLoopFuture<Bool> {
        if let newRule = savePolicyLine(ptype: ptype, rule: rule) {
            return Actions.addPolicy(db: database, rule: newRule).map {
                true
            }
        }
        return database.eventLoop.makeSucceededFuture(false)
    }
    
    public func addPolicies(sec: String, ptype: String, rules: [[String]]) -> EventLoopFuture<Bool> {
        let newRules = rules.compactMap { savePolicyLine(ptype: ptype, rule: $0) }
        return Actions.savePolicy(db: database, rules: newRules).map {
            true
        }
    }
    
    public func removePolicy(sec: String, ptype: String, rule: [String]) -> EventLoopFuture<Bool> {
        Actions.removePolicy(db: database, ptype: ptype, rule: rule).map {
            true
        }
    }
    
    public func removePolicies(sec: String, ptype: String, rules: [[String]]) -> EventLoopFuture<Bool> {
        Actions.removePolicies(db: database, ptype: ptype, rules: rules).map {
            true
        }
    }
    
    public func removeFilteredPolicy(sec: String, ptype: String, fieldIndex: Int, fieldValues: [String]) -> EventLoopFuture<Bool> {
        if fieldIndex <= 5 && !fieldValues.isEmpty {
            return Actions.removeFilteredPolicy(db: database, ptype: ptype, fieldIndex: fieldIndex, fieldValues: fieldValues).map {
                true
            }
        } else {
           return database.eventLoop.makeSucceededFuture(false)
        }
    }
}

