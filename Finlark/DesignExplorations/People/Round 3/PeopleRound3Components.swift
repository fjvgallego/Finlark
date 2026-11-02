//
//  PeopleRound3Components.swift
//  Finlark
//
//  FIN-9 People, Round 3: Ginger with Saffron's round check button, which the owner picked from Round 2.
//  The list is settled, so the variants share it: Iris's header, a check on each row that completes the
//  repayment, and Undo in a toast instead of a confirmation. Remind is gone from the list and the main
//  actions; the share reminder (NTF-003) stays as a toolbar icon on the person until the owner decides
//  whether it stays in v1. The variants differ only in how a single share is paid on the person.
//

#if DEBUG
import SwiftUI

// MARK: - Actions

extension PPStore {
    /// Settle all for a person today (SPL-008) and returns what Undo needs.
    func settleAllWithUndo(_ person: PPPerson) -> P2Undo? {
        let total = person.owed.formatted(.currency(code: code))
        let repayments = settleAll(person.id)
        guard !repayments.isEmpty else { return nil }
        return P2Undo(
            message: String(localized: "Settled \(total) with \(person.name)"),
            personID: person.id,
            repaymentIDs: repayments.map(\.id)
        )
    }
}
#endif
