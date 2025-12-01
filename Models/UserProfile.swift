//
//  UserProfile.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import SwiftUI

// MARK: - Special Date Type
enum SpecialDateType: String, CaseIterable, Codable {
    case birthday
    case anniversary
    case spouseBirthday
    case childBirthday
    case petBirthday
    case graduation

    var color: Color {
        switch self {
        case .birthday:
            return Color.yellow // Gold/yellow for user's birthday
        case .anniversary:
            return Color.pink // Pink/rose for anniversary
        case .spouseBirthday:
            return Color.purple.opacity(0.6) // Light purple for spouse
        case .childBirthday:
            return Color.blue.opacity(0.6) // Light blue for children
        case .petBirthday:
            return Color.green.opacity(0.6) // Light green for pets
        case .graduation:
            return Color.orange // Orange for graduation
        }
    }

    var icon: String {
        switch self {
        case .birthday:
            return "star.fill" // Star for user's birthday
        case .anniversary:
            return "heart.fill" // Heart for anniversary
        case .spouseBirthday:
            return "person.fill" // Person for spouse
        case .childBirthday:
            return "figure.child" // Child figure
        case .petBirthday:
            return "pawprint.fill" // Paw for pets
        case .graduation:
            return "graduationcap.fill" // Mortarboard cap
        }
    }

    var displayName: String {
        switch self {
        case .birthday:
            return "Birthday"
        case .anniversary:
            return "Anniversary"
        case .spouseBirthday:
            return "Spouse Birthday"
        case .childBirthday:
            return "Child Birthday"
        case .petBirthday:
            return "Pet Birthday"
        case .graduation:
            return "Graduation"
        }
    }
}

// MARK: - Special Date
struct SpecialDate: Equatable {
    let date: Date
    let type: SpecialDateType
    let label: String
}

// MARK: - Child Struct
struct Child: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var dateOfBirth: Date

    init(id: UUID = UUID(), name: String = "", dateOfBirth: Date = Date()) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "dateOfBirth": dateOfBirth
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> Child? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String else {
            return nil
        }

        var dateOfBirth = Date()
        if let timestamp = dict["dateOfBirth"] as? Date {
            dateOfBirth = timestamp
        }

        return Child(id: id, name: name, dateOfBirth: dateOfBirth)
    }
}

// MARK: - Pet Struct
struct Pet: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: PetType
    var birthday: Date?

    init(id: UUID = UUID(), name: String = "", type: PetType = .dog, birthday: Date? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.birthday = birthday
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "type": type.rawValue
        ]
        if let birthday = birthday {
            dict["birthday"] = birthday
        }
        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> Pet? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let typeString = dict["type"] as? String,
              let type = PetType(rawValue: typeString) else {
            return nil
        }

        var birthday: Date? = nil
        if let timestamp = dict["birthday"] as? Date {
            birthday = timestamp
        }

        return Pet(id: id, name: name, type: type, birthday: birthday)
    }
}

// MARK: - Pet Type Enum
enum PetType: String, Codable, CaseIterable {
    case dog = "Dog"
    case cat = "Cat"
    case bird = "Bird"
    case fish = "Fish"
    case hamster = "Hamster"
    case rabbit = "Rabbit"
    case other = "Other"

    var displayName: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .bird: return "bird.fill"
        case .fish: return "fish.fill"
        case .hamster: return "hare.fill"
        case .rabbit: return "hare.fill"
        case .other: return "pawprint.fill"
        }
    }
}

struct UserProfile: Codable {
    // Authentication fields
    var userId: String?
    var email: String?
    var isAnonymous: Bool = true

    // Profile data
    var name: String
    var dateOfBirth: Date

    // Education
    var degree: String
    var schoolName: String
    var graduationYear: Int

    // Work
    var industry: String
    var jobRole: String
    var yearsWorked: Double

    // Family
    var relationshipStatus: RelationshipStatus
    var spouseName: String
    var spouseDateOfBirth: Date?
    var marriageDate: Date?
    var children: [Child]
    var pets: [Pet]

    // Legacy fields for backward compatibility
    var numberOfKids: Int {
        return children.count
    }
    var numberOfPets: Int {
        return pets.count
    }

    // Computed properties
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }

    var birthYear: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: dateOfBirth)
    }

    var nostalgiaEra: NostalgiaEra {
        let year = birthYear
        switch year {
        case 1975...1985:
            return .eighties
        case 1986...1995:
            return .nineties
        case 1996...2005:
            return .earlyTwoThousands
        case 2006...2015:
            return .twentyTens
        default:
            return .modern
        }
    }

    init(
        userId: String? = nil,
        email: String? = nil,
        isAnonymous: Bool = true,
        name: String = "",
        dateOfBirth: Date = Date(),
        degree: String = "",
        schoolName: String = "",
        graduationYear: Int = Calendar.current.component(.year, from: Date()),
        industry: String = "",
        jobRole: String = "",
        yearsWorked: Double = 0,
        relationshipStatus: RelationshipStatus = .single,
        spouseName: String = "",
        spouseDateOfBirth: Date? = nil,
        marriageDate: Date? = nil,
        children: [Child] = [],
        pets: [Pet] = []
    ) {
        self.userId = userId
        self.email = email
        self.isAnonymous = isAnonymous
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.degree = degree
        self.schoolName = schoolName
        self.graduationYear = graduationYear
        self.industry = industry
        self.jobRole = jobRole
        self.yearsWorked = yearsWorked
        self.relationshipStatus = relationshipStatus
        self.spouseName = spouseName
        self.spouseDateOfBirth = spouseDateOfBirth
        self.marriageDate = marriageDate
        self.children = children
        self.pets = pets
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId ?? "",
            "email": email ?? "",
            "isAnonymous": isAnonymous,
            "name": name,
            "dateOfBirth": dateOfBirth,
            "degree": degree,
            "schoolName": schoolName,
            "graduationYear": graduationYear,
            "industry": industry,
            "jobRole": jobRole,
            "yearsWorked": yearsWorked,
            "relationshipStatus": relationshipStatus.rawValue,
            "spouseName": spouseName,
            "children": children.map { $0.toDictionary() },
            "pets": pets.map { $0.toDictionary() }
        ]

        // Add optional dates
        if let spouseDOB = spouseDateOfBirth {
            dict["spouseDateOfBirth"] = spouseDOB
        }
        if let marriage = marriageDate {
            dict["marriageDate"] = marriage
        }

        return dict
    }

    // MARK: - Special Dates Helper
    /// Returns all special dates from the user profile
    func getSpecialDates() -> [SpecialDate] {
        var specialDates: [SpecialDate] = []
        let calendar = Calendar.current

        // 1. User's birthday (recurring annually)
        specialDates.append(SpecialDate(
            date: dateOfBirth,
            type: .birthday,
            label: "My Birthday"
        ))

        // 2. Marriage date/Anniversary (if married)
        if let marriage = marriageDate {
            specialDates.append(SpecialDate(
                date: marriage,
                type: .anniversary,
                label: "Our Wedding Anniversary"
            ))
        }

        // 3. Spouse's birthday (if married and has spouse info)
        if let spouseBday = spouseDateOfBirth, !spouseName.isEmpty {
            specialDates.append(SpecialDate(
                date: spouseBday,
                type: .spouseBirthday,
                label: "\(spouseName)'s Birthday"
            ))
        }

        // 4. Children's birthdays
        for child in children {
            if !child.name.isEmpty {
                specialDates.append(SpecialDate(
                    date: child.dateOfBirth,
                    type: .childBirthday,
                    label: "\(child.name)'s Birthday"
                ))
            }
        }

        // 5. Pet birthdays
        for pet in pets {
            if let birthday = pet.birthday, !pet.name.isEmpty {
                specialDates.append(SpecialDate(
                    date: birthday,
                    type: .petBirthday,
                    label: "\(pet.name)'s Birthday"
                ))
            }
        }

        // 6. Graduation date
        if !schoolName.isEmpty && graduationYear > 0 {
            // Create a date for graduation (assume June 1st of graduation year)
            if let gradDate = calendar.date(from: DateComponents(year: graduationYear, month: 6, day: 1)) {
                specialDates.append(SpecialDate(
                    date: gradDate,
                    type: .graduation,
                    label: "Graduation from \(schoolName)"
                ))
            }
        }

        return specialDates
    }

    /// Check if a specific date matches any special date (by month and day for recurring dates)
    /// Only returns special dates on or after the year they actually happened
    func getSpecialDateType(for date: Date) -> SpecialDateType? {
        let calendar = Calendar.current
        let dateMonth = calendar.component(.month, from: date)
        let dateDay = calendar.component(.day, from: date)
        let dateYear = calendar.component(.year, from: date)

        // Check user's birthday (recurring - match month/day, always valid since birth)
        let birthMonth = calendar.component(.month, from: dateOfBirth)
        let birthDay = calendar.component(.day, from: dateOfBirth)
        let birthYear = calendar.component(.year, from: dateOfBirth)
        if dateMonth == birthMonth && dateDay == birthDay && dateYear >= birthYear {
            return .birthday
        }

        // Check anniversary (recurring - match month/day, only on/after marriage year)
        if let marriage = marriageDate {
            let marriageMonth = calendar.component(.month, from: marriage)
            let marriageDay = calendar.component(.day, from: marriage)
            let marriageYear = calendar.component(.year, from: marriage)
            if dateMonth == marriageMonth && dateDay == marriageDay && dateYear >= marriageYear {
                return .anniversary
            }
        }

        // Check spouse's birthday (recurring - match month/day, only on/after marriage year)
        if let spouseBday = spouseDateOfBirth, let marriage = marriageDate {
            let spouseMonth = calendar.component(.month, from: spouseBday)
            let spouseDay = calendar.component(.day, from: spouseBday)
            let marriageYear = calendar.component(.year, from: marriage)
            if dateMonth == spouseMonth && dateDay == spouseDay && dateYear >= marriageYear {
                return .spouseBirthday
            }
        }

        // Check children's birthdays (recurring - match month/day, only on/after child's birth year)
        for child in children {
            let childMonth = calendar.component(.month, from: child.dateOfBirth)
            let childDay = calendar.component(.day, from: child.dateOfBirth)
            let childBirthYear = calendar.component(.year, from: child.dateOfBirth)
            if dateMonth == childMonth && dateDay == childDay && dateYear >= childBirthYear {
                return .childBirthday
            }
        }

        // Check pet birthdays (recurring - match month/day, only on/after pet's birth year)
        for pet in pets {
            if let birthday = pet.birthday {
                let petMonth = calendar.component(.month, from: birthday)
                let petDay = calendar.component(.day, from: birthday)
                let petBirthYear = calendar.component(.year, from: birthday)
                if dateMonth == petMonth && dateDay == petDay && dateYear >= petBirthYear {
                    return .petBirthday
                }
            }
        }

        // Check graduation (one-time event - match exact year/month/day)
        if !schoolName.isEmpty && graduationYear > 0 {
            if dateYear == graduationYear && dateMonth == 6 && dateDay == 1 {
                return .graduation
            }
        }

        return nil
    }

    /// Get all special dates for a specific date (can have multiple, e.g., birthday + anniversary)
    /// Only returns special dates on or after the year they actually happened
    func getAllSpecialDateTypes(for date: Date) -> [SpecialDateType] {
        let calendar = Calendar.current
        let dateMonth = calendar.component(.month, from: date)
        let dateDay = calendar.component(.day, from: date)
        let dateYear = calendar.component(.year, from: date)

        var types: [SpecialDateType] = []

        // Check user's birthday (only on/after birth year)
        let birthMonth = calendar.component(.month, from: dateOfBirth)
        let birthDay = calendar.component(.day, from: dateOfBirth)
        let birthYear = calendar.component(.year, from: dateOfBirth)
        if dateMonth == birthMonth && dateDay == birthDay && dateYear >= birthYear {
            types.append(.birthday)
        }

        // Check anniversary (only on/after marriage year)
        if let marriage = marriageDate {
            let marriageMonth = calendar.component(.month, from: marriage)
            let marriageDay = calendar.component(.day, from: marriage)
            let marriageYear = calendar.component(.year, from: marriage)
            if dateMonth == marriageMonth && dateDay == marriageDay && dateYear >= marriageYear {
                types.append(.anniversary)
            }
        }

        // Check spouse's birthday (only on/after marriage year)
        if let spouseBday = spouseDateOfBirth, let marriage = marriageDate {
            let spouseMonth = calendar.component(.month, from: spouseBday)
            let spouseDay = calendar.component(.day, from: spouseBday)
            let marriageYear = calendar.component(.year, from: marriage)
            if dateMonth == spouseMonth && dateDay == spouseDay && dateYear >= marriageYear {
                types.append(.spouseBirthday)
            }
        }

        // Check children's birthdays (only on/after each child's birth year)
        for child in children {
            let childMonth = calendar.component(.month, from: child.dateOfBirth)
            let childDay = calendar.component(.day, from: child.dateOfBirth)
            let childBirthYear = calendar.component(.year, from: child.dateOfBirth)
            if dateMonth == childMonth && dateDay == childDay && dateYear >= childBirthYear {
                types.append(.childBirthday)
            }
        }

        // Check pet birthdays (only on/after each pet's birth year)
        for pet in pets {
            if let birthday = pet.birthday {
                let petMonth = calendar.component(.month, from: birthday)
                let petDay = calendar.component(.day, from: birthday)
                let petBirthYear = calendar.component(.year, from: birthday)
                if dateMonth == petMonth && dateDay == petDay && dateYear >= petBirthYear {
                    types.append(.petBirthday)
                }
            }
        }

        // Check graduation (one-time)
        if !schoolName.isEmpty && graduationYear > 0 {
            if dateYear == graduationYear && dateMonth == 6 && dateDay == 1 {
                types.append(.graduation)
            }
        }

        return types
    }

    // Create from Firestore dictionary
    static func fromDictionary(_ dict: [String: Any]) -> UserProfile? {
        guard let name = dict["name"] as? String else {
            return nil
        }

        var dateOfBirth = Date()
        if let timestamp = dict["dateOfBirth"] as? Date {
            dateOfBirth = timestamp
        }

        let userId = dict["userId"] as? String
        let email = dict["email"] as? String
        let isAnonymous = dict["isAnonymous"] as? Bool ?? true
        let degree = dict["degree"] as? String ?? ""
        let schoolName = dict["schoolName"] as? String ?? ""
        let graduationYear = dict["graduationYear"] as? Int ?? Calendar.current.component(.year, from: Date())
        let industry = dict["industry"] as? String ?? ""
        let jobRole = dict["jobRole"] as? String ?? ""
        let yearsWorked = dict["yearsWorked"] as? Double ?? 0
        let relationshipStatusString = dict["relationshipStatus"] as? String ?? "Single"
        let relationshipStatus = RelationshipStatus(rawValue: relationshipStatusString) ?? .single
        let spouseName = dict["spouseName"] as? String ?? ""

        var spouseDateOfBirth: Date? = nil
        if let timestamp = dict["spouseDateOfBirth"] as? Date {
            spouseDateOfBirth = timestamp
        }

        var marriageDate: Date? = nil
        if let timestamp = dict["marriageDate"] as? Date {
            marriageDate = timestamp
        }

        var children: [Child] = []
        if let childrenArray = dict["children"] as? [[String: Any]] {
            children = childrenArray.compactMap { Child.fromDictionary($0) }
        }

        var pets: [Pet] = []
        if let petsArray = dict["pets"] as? [[String: Any]] {
            pets = petsArray.compactMap { Pet.fromDictionary($0) }
        }

        return UserProfile(
            userId: userId,
            email: email,
            isAnonymous: isAnonymous,
            name: name,
            dateOfBirth: dateOfBirth,
            degree: degree,
            schoolName: schoolName,
            graduationYear: graduationYear,
            industry: industry,
            jobRole: jobRole,
            yearsWorked: yearsWorked,
            relationshipStatus: relationshipStatus,
            spouseName: spouseName,
            spouseDateOfBirth: spouseDateOfBirth,
            marriageDate: marriageDate,
            children: children,
            pets: pets
        )
    }
}

enum RelationshipStatus: String, Codable, CaseIterable {
    case single = "Single"
    case inRelationship = "In a Relationship"
    case married = "Married"
    case divorced = "Divorced"
    case widowed = "Widowed"

    var displayName: String {
        return self.rawValue
    }
}

enum NostalgiaEra: String {
    case eighties = "1980s"
    case nineties = "1990s"
    case earlyTwoThousands = "2000s"
    case twentyTens = "2010s"
    case modern = "Modern"
}
