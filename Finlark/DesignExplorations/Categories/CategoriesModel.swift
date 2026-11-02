//
//  CategoriesModel.swift
//  Finlark
//
//  FIN-9 Categories: the mock data behind the Categories explorations (CAT-001…003). Appendix A's
//  default categories with made-up usage, a custom one, three archived ones, and the recurring templates
//  that use them, so archiving Subscriptions asks for a replacement for Netflix and Spotify (CAT-003).
//  Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

// MARK: - Colors

/// The colors a category can take, each with a name so the picker and VoiceOver can say it. Yellow is
/// left out: a yellow symbol on its pale tint doesn't have enough contrast in light mode.
enum CTColor: String, CaseIterable, Identifiable {
    case red, orange, brown, green, mint, teal, cyan, blue, indigo, purple, pink, gray

    var id: Self { self }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .brown: .brown
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .gray: .gray
        }
    }

    var name: LocalizedStringKey {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .brown: "Brown"
        case .green: "Green"
        case .mint: "Mint"
        case .teal: "Teal"
        case .cyan: "Cyan"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .gray: "Gray"
        }
    }
}

// MARK: - Symbols

/// An SF Symbol a category can use, with a name for VoiceOver and words to find it by. A curated set:
/// there's no public API to list every SF Symbol, and most of them don't suit a category.
struct CTSymbol: Identifiable {
    let name: String
    let label: LocalizedStringResource
    /// Words that find it in search and suggest it from a category's name. Localized with the app.
    let keywords: LocalizedStringResource

    var id: String { name }

    init(_ name: String, _ label: LocalizedStringResource, keywords: LocalizedStringResource) {
        self.name = name
        self.label = label
        self.keywords = keywords
    }

    /// Whether a word of the query starts one of its words. Suggestions ignore words shorter than
    /// `minimumLength`, so "Gym" suggests a dumbbell but "a" doesn't suggest everything.
    func matches(_ query: String, minimumLength: Int = 1) -> Bool {
        let words = query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let haystack = "\(String(localized: label)) \(String(localized: keywords))".lowercased()
            .split(separator: " ")
        return words.contains { word in
            word.count >= minimumLength && haystack.contains { $0.hasPrefix(word) }
        }
    }
}

struct CTSymbolGroup: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let symbols: [CTSymbol]

    static let all: [CTSymbolGroup] = [
        CTSymbolGroup(id: "food", title: "Food & Drink", symbols: [
            CTSymbol("cart.fill", "Cart", keywords: "groceries supermarket food shop"),
            CTSymbol("basket.fill", "Basket", keywords: "groceries market food"),
            CTSymbol("carrot.fill", "Carrot", keywords: "groceries vegetables veggie food"),
            CTSymbol("fork.knife", "Fork and knife", keywords: "dining restaurant eating food lunch dinner"),
            CTSymbol("takeoutbag.and.cup.and.straw.fill", "Takeaway", keywords: "takeaway delivery fast food dining"),
            CTSymbol("cup.and.saucer.fill", "Coffee cup", keywords: "coffee cafe breakfast"),
            CTSymbol("mug.fill", "Mug", keywords: "coffee tea"),
            CTSymbol("wineglass.fill", "Wine glass", keywords: "drinks bar wine alcohol"),
            CTSymbol("birthday.cake.fill", "Cake", keywords: "birthday party bakery"),
            CTSymbol("popcorn.fill", "Popcorn", keywords: "snacks cinema movies"),
        ]),
        CTSymbolGroup(id: "transport", title: "Transport", symbols: [
            CTSymbol("car.fill", "Car", keywords: "car transport insurance parking"),
            CTSymbol("fuelpump.fill", "Fuel pump", keywords: "fuel petrol gas diesel"),
            CTSymbol("tram.fill", "Tram", keywords: "transport metro tram public"),
            CTSymbol("bus.fill", "Bus", keywords: "transport bus public"),
            CTSymbol("train.side.front.car", "Train", keywords: "train rail transport"),
            CTSymbol("bicycle", "Bicycle", keywords: "bike cycling"),
            CTSymbol("scooter", "Scooter", keywords: "scooter"),
            CTSymbol("parkingsign.circle.fill", "Parking", keywords: "parking car"),
            CTSymbol("airplane", "Airplane", keywords: "travel flights holidays trips"),
            CTSymbol("ferry.fill", "Ferry", keywords: "ferry boat travel"),
        ]),
        CTSymbolGroup(id: "home", title: "Home", symbols: [
            CTSymbol("house.fill", "House", keywords: "housing rent mortgage home"),
            CTSymbol("key.fill", "Key", keywords: "rent housing deposit"),
            CTSymbol("bolt.fill", "Bolt", keywords: "bills utilities electricity power"),
            CTSymbol("drop.fill", "Drop", keywords: "water bills utilities"),
            CTSymbol("flame.fill", "Flame", keywords: "gas heating bills utilities"),
            CTSymbol("wifi", "Wi-Fi", keywords: "internet broadband bills"),
            CTSymbol("phone.fill", "Phone", keywords: "phone mobile bills"),
            CTSymbol("sofa.fill", "Sofa", keywords: "furniture home"),
            CTSymbol("lightbulb.fill", "Light bulb", keywords: "electricity home"),
            CTSymbol("wrench.and.screwdriver.fill", "Tools", keywords: "repairs maintenance diy"),
            CTSymbol("washer.fill", "Washing machine", keywords: "laundry cleaning appliances"),
        ]),
        CTSymbolGroup(id: "health", title: "Health & Fitness", symbols: [
            CTSymbol("heart.fill", "Heart", keywords: "health"),
            CTSymbol("cross.case.fill", "First aid", keywords: "health doctor medical"),
            CTSymbol("pills.fill", "Pills", keywords: "pharmacy medicine health"),
            CTSymbol("stethoscope", "Stethoscope", keywords: "doctor medical health"),
            CTSymbol("bandage.fill", "Bandage", keywords: "pharmacy health"),
            CTSymbol("brain.head.profile", "Head", keywords: "therapy mental health"),
            CTSymbol("dumbbell.fill", "Dumbbell", keywords: "gym fitness sport"),
            CTSymbol("figure.run", "Runner", keywords: "sport fitness running gym"),
            CTSymbol("leaf.fill", "Leaf", keywords: "wellness nature garden"),
        ]),
        CTSymbolGroup(id: "shopping", title: "Shopping", symbols: [
            CTSymbol("bag.fill", "Bag", keywords: "shopping store"),
            CTSymbol("handbag.fill", "Handbag", keywords: "shopping fashion accessories"),
            CTSymbol("tshirt.fill", "T-shirt", keywords: "clothes clothing fashion"),
            CTSymbol("hanger", "Hanger", keywords: "clothes clothing laundry"),
            CTSymbol("eyeglasses", "Glasses", keywords: "glasses optician"),
            CTSymbol("laptopcomputer", "Laptop", keywords: "electronics tech computer"),
            CTSymbol("iphone", "iPhone", keywords: "electronics tech phone"),
            CTSymbol("shippingbox.fill", "Box", keywords: "online orders delivery shopping"),
            CTSymbol("tag.fill", "Tag", keywords: "sales shopping"),
            CTSymbol("gift.fill", "Gift", keywords: "gifts presents birthday"),
        ]),
        CTSymbolGroup(id: "leisure", title: "Leisure", symbols: [
            CTSymbol("theatermasks.fill", "Theater masks", keywords: "leisure entertainment theater"),
            CTSymbol("film.fill", "Film", keywords: "cinema movies"),
            CTSymbol("tv.fill", "TV", keywords: "subscriptions streaming tv"),
            CTSymbol("music.note", "Music", keywords: "music concerts subscriptions"),
            CTSymbol("gamecontroller.fill", "Game controller", keywords: "games gaming"),
            CTSymbol("book.fill", "Book", keywords: "books reading"),
            CTSymbol("ticket.fill", "Ticket", keywords: "tickets events concerts"),
            CTSymbol("camera.fill", "Camera", keywords: "photography hobbies"),
            CTSymbol("paintpalette.fill", "Palette", keywords: "art hobbies crafts"),
            CTSymbol("sportscourt.fill", "Court", keywords: "sport football tennis"),
            CTSymbol("beach.umbrella.fill", "Beach umbrella", keywords: "holidays vacation beach travel"),
            CTSymbol("tent.fill", "Tent", keywords: "camping outdoors travel"),
            CTSymbol("suitcase.fill", "Suitcase", keywords: "travel trips holidays luggage"),
        ]),
        CTSymbolGroup(id: "money", title: "Money", symbols: [
            CTSymbol("banknote.fill", "Banknote", keywords: "salary wages cash pay"),
            CTSymbol("briefcase.fill", "Briefcase", keywords: "work freelance business salary"),
            CTSymbol("building.columns.fill", "Bank", keywords: "bank fees taxes"),
            CTSymbol("creditcard.fill", "Credit card", keywords: "card fees payments"),
            CTSymbol("wallet.bifold.fill", "Wallet", keywords: "wallet cash pocket money"),
            CTSymbol("chart.line.uptrend.xyaxis", "Chart", keywords: "investments savings interest dividends"),
            CTSymbol("chart.pie.fill", "Pie chart", keywords: "investments savings"),
            CTSymbol("percent", "Percent", keywords: "interest taxes discount"),
            CTSymbol("arrow.uturn.backward", "Return arrow", keywords: "refunds returns"),
            CTSymbol("giftcard.fill", "Gift card", keywords: "gift card vouchers"),
            CTSymbol("plus.square.fill", "Plus", keywords: "other income extra"),
        ]),
        CTSymbolGroup(id: "life", title: "Family & Other", symbols: [
            CTSymbol("pawprint.fill", "Paw print", keywords: "pets dog cat vet"),
            CTSymbol("figure.and.child.holdinghands", "Parent and child", keywords: "kids children family childcare"),
            CTSymbol("stroller.fill", "Stroller", keywords: "baby kids"),
            CTSymbol("graduationcap.fill", "Graduation cap", keywords: "education school university courses"),
            CTSymbol("person.2.fill", "People", keywords: "family friends"),
            CTSymbol("scissors", "Scissors", keywords: "haircut beauty hairdresser"),
            CTSymbol("umbrella.fill", "Umbrella", keywords: "insurance"),
            CTSymbol("shield.fill", "Shield", keywords: "insurance security"),
            CTSymbol("doc.text.fill", "Document", keywords: "taxes paperwork admin"),
            CTSymbol("envelope.fill", "Envelope", keywords: "post mail"),
            CTSymbol("star.fill", "Star", keywords: "favorite special"),
            CTSymbol("sparkles", "Sparkles", keywords: "cleaning beauty"),
            CTSymbol("square.grid.2x2.fill", "Grid", keywords: "other miscellaneous"),
        ]),
    ]

    static var allSymbols: [CTSymbol] { all.flatMap(\.symbols) }

    static func symbol(named name: String) -> CTSymbol? {
        allSymbols.first { $0.name == name }
    }

    /// Symbols whose words match a category's name, for suggestions as it's typed.
    static func suggestions(for name: String) -> [CTSymbol] {
        allSymbols.filter { $0.matches(name, minimumLength: 3) }
    }
}

// MARK: - Category

struct CTCategory: Identifiable, Hashable {
    let id: String
    var name: String
    var type: ExplorationTransactionType
    var symbol: String
    var color: CTColor
    var isArchived = false
    /// Mocked usage: how many transactions use it, and its spending (or income) this month.
    var transactionCount = 0
    var thisMonth: Decimal = 0

    /// Its type is fixed once it has transactions (CAT-002).
    var canChangeType: Bool { transactionCount == 0 }

    /// For the shared icon views, which only read the symbol and the color.
    var icon: ExplorationCategory {
        ExplorationCategory(id: id, name: LocalizedStringResource(stringLiteral: name), symbol: symbol, color: color.color)
    }
}

/// A recurring template that uses a category. Archiving the category asks for a replacement (CAT-003).
struct CTTemplateUse: Identifiable {
    let id: String
    let title: String
    var categoryID: CTCategory.ID
}

enum CTNameIssue {
    case empty
    case duplicate(ExplorationTransactionType, String)

    var message: Text? {
        switch self {
        case .empty:
            nil
        case .duplicate(.expense, let name):
            Text("You already have an expense category called “\(name)”.")
        case .duplicate(.income, let name):
            Text("You already have an income category called “\(name)”.")
        }
    }
}

// MARK: - Store

@Observable
final class CTStore {
    var categories: [CTCategory]
    var templates: [CTTemplateUse]
    let code = "EUR"

    init(categories: [CTCategory], templates: [CTTemplateUse]) {
        self.categories = categories
        self.templates = templates
    }

    func category(_ id: CTCategory.ID) -> CTCategory? {
        categories.first { $0.id == id }
    }

    func active(_ type: ExplorationTransactionType) -> [CTCategory] {
        categories.filter { $0.type == type && !$0.isArchived }
    }

    func archived(_ type: ExplorationTransactionType) -> [CTCategory] {
        categories.filter { $0.type == type && $0.isArchived }
    }

    var archived: [CTCategory] { categories.filter(\.isArchived) }

    func templates(using id: CTCategory.ID) -> [CTTemplateUse] {
        templates.filter { $0.categoryID == id }
    }

    /// Every transaction needs a category, so the last active one of a type can't be archived.
    func isLastActive(_ category: CTCategory) -> Bool {
        !category.isArchived && active(category.type).count == 1
    }

    /// Names are required and unique among active categories of the same type, ignoring case (CAT-001).
    func nameIssue(_ name: String, type: ExplorationTransactionType, excluding id: CTCategory.ID?) -> CTNameIssue? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        let clash = active(type).first {
            $0.id != id && $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        return clash.map { .duplicate(type, $0.name) }
    }

    func save(_ category: CTCategory) {
        var category = category
        category.name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
    }

    /// Archives it, moving the recurring templates that use it to their replacements first (CAT-003).
    func archive(_ id: CTCategory.ID, replacements: [CTTemplateUse.ID: CTCategory.ID] = [:]) {
        for index in templates.indices where templates[index].categoryID == id {
            if let replacement = replacements[templates[index].id] {
                templates[index].categoryID = replacement
            }
        }
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].isArchived = true
        }
    }

    /// Brings it back, unless an active category of its type now has its name. Returns that clash.
    @discardableResult
    func unarchive(_ id: CTCategory.ID) -> CTNameIssue? {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return nil }
        let category = categories[index]
        if let issue = nameIssue(category.name, type: category.type, excluding: id) {
            return issue
        }
        categories[index].isArchived = false
        return nil
    }
}

// MARK: - Samples

extension CTStore {
    /// Appendix A's defaults, a custom Pets category, and Coffee, Gym and Freelance archived.
    static var sample: CTStore {
        CTStore(categories: sampleCategories, templates: sampleTemplates)
    }

    /// Just after onboarding: the defaults, unused, nothing archived (ONB-004).
    static var fresh: CTStore {
        CTStore(
            categories: sampleCategories
                .filter { !$0.isArchived && $0.id != "pets" }
                .map { category in
                    var category = category
                    category.transactionCount = 0
                    category.thisMonth = 0
                    return category
                },
            templates: []
        )
    }

    // Icons and colors match the other explorations' proposals (Appendix A leaves them to UI design).
    private static var sampleCategories: [CTCategory] {
        [
            CTCategory(id: "groceries", name: String(localized: "Groceries"), type: .expense, symbol: "cart.fill",
                       color: .green, transactionCount: 142, thisMonth: 312.40),
            CTCategory(id: "dining", name: String(localized: "Dining"), type: .expense, symbol: "fork.knife",
                       color: .orange, transactionCount: 58, thisMonth: 148.50),
            CTCategory(id: "transport", name: String(localized: "Transport"), type: .expense, symbol: "tram.fill",
                       color: .blue, transactionCount: 41, thisMonth: 54),
            CTCategory(id: "fuel", name: String(localized: "Fuel"), type: .expense, symbol: "fuelpump.fill",
                       color: .brown, transactionCount: 23, thisMonth: 86.20),
            CTCategory(id: "housing", name: String(localized: "Housing"), type: .expense, symbol: "house.fill",
                       color: .indigo, transactionCount: 12, thisMonth: 750),
            CTCategory(id: "bills", name: String(localized: "Bills & Utilities"), type: .expense, symbol: "bolt.fill",
                       color: .teal, transactionCount: 36, thisMonth: 118.35),
            CTCategory(id: "health", name: String(localized: "Health"), type: .expense, symbol: "heart.fill",
                       color: .pink, transactionCount: 9, thisMonth: 45),
            CTCategory(id: "shopping", name: String(localized: "Shopping"), type: .expense, symbol: "bag.fill",
                       color: .mint, transactionCount: 27, thisMonth: 89.99),
            CTCategory(id: "leisure", name: String(localized: "Leisure"), type: .expense, symbol: "theatermasks.fill",
                       color: .purple, transactionCount: 31, thisMonth: 62),
            CTCategory(id: "subscriptions", name: String(localized: "Subscriptions"), type: .expense, symbol: "tv.fill",
                       color: .red, transactionCount: 48, thisMonth: 32.98),
            CTCategory(id: "travel", name: String(localized: "Travel"), type: .expense, symbol: "airplane",
                       color: .cyan),
            CTCategory(id: "other", name: String(localized: "Other"), type: .expense, symbol: "square.grid.2x2.fill",
                       color: .gray, transactionCount: 5, thisMonth: 12),
            CTCategory(id: "pets", name: "Pets", type: .expense, symbol: "pawprint.fill",
                       color: .brown, transactionCount: 7, thisMonth: 38.50),
            CTCategory(id: "coffee", name: "Coffee", type: .expense, symbol: "cup.and.saucer.fill",
                       color: .brown, isArchived: true, transactionCount: 64),
            CTCategory(id: "gym", name: "Gym", type: .expense, symbol: "dumbbell.fill",
                       color: .red, isArchived: true, transactionCount: 18),
            CTCategory(id: "salary", name: String(localized: "Salary"), type: .income, symbol: "banknote.fill",
                       color: .mint, transactionCount: 10, thisMonth: 2150),
            CTCategory(id: "refunds", name: String(localized: "Refunds"), type: .income, symbol: "arrow.uturn.backward",
                       color: .blue, transactionCount: 6, thisMonth: 24.99),
            CTCategory(id: "gifts", name: String(localized: "Gifts"), type: .income, symbol: "gift.fill",
                       color: .pink, transactionCount: 2),
            CTCategory(id: "other-income", name: String(localized: "Other income"), type: .income,
                       symbol: "plus.square.fill", color: .gray),
            CTCategory(id: "freelance", name: "Freelance", type: .income, symbol: "briefcase.fill",
                       color: .indigo, isArchived: true, transactionCount: 14),
        ]
    }

    private static var sampleTemplates: [CTTemplateUse] {
        [
            CTTemplateUse(id: "rent", title: "Rent", categoryID: "housing"),
            CTTemplateUse(id: "electricity", title: "Electricity", categoryID: "bills"),
            CTTemplateUse(id: "phone", title: "Phone plan", categoryID: "bills"),
            CTTemplateUse(id: "gym", title: "Gym", categoryID: "health"),
            CTTemplateUse(id: "netflix", title: "Netflix", categoryID: "subscriptions"),
            CTTemplateUse(id: "spotify", title: "Spotify", categoryID: "subscriptions"),
            CTTemplateUse(id: "veggie-box", title: "Veggie box", categoryID: "groceries"),
            CTTemplateUse(id: "car-insurance", title: "Car insurance", categoryID: "transport"),
            CTTemplateUse(id: "salary", title: "Salary", categoryID: "salary"),
        ]
    }
}
#endif
