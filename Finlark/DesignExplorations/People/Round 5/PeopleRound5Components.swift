//
//  PeopleRound5Components.swift
//  Finlark
//
//  FIN-9 People, Round 5: the owner's notes on Round 4. Recording part of a share must not hide behind a
//  touch and hold, so every share row shows two controls, one for paid in full (SPL-006) and one for
//  part (SPL-007), and neither sits at the leading edge, where a check reads like a to-do list. Anise's
//  glass layout and the Undo toast stay. The list stays Round 3's `P3People`.
//

#if DEBUG
import SwiftUI

// MARK: - Share text

/// The ticket and the date, with the status words for VoiceOver, since rows no longer print "Pending".
struct P5ShareTitle: View {
    let share: PPShare
    let code: String
    var showsPaid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: share.ticket)
                .font(.headline)
            Text(share.date, format: .dateTime.weekday().day().month())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if showsPaid, share.paid > 0 {
                Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(share.statusText(code: code))
    }
}
#endif
