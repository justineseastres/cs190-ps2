//
//  CPUState.swift
//  Counter
//
//  Created by Brian Hill github.com/brianhill on 2/12/16.
//

// CPUState defines the various CPU registers we need to simulate an HP-35.
//
// This reference is the most thorough, but at the moment a bunch of the image links are broken:
//
// http://home.citycable.ch/pierrefleur/Jacques-Laporte/A&R.htm
//
// This reference is sufficient:
//
// http://www.hpmuseum.org/techcpu.htm

import Foundation

typealias Nibble = UInt8 // This should be UInt4, but the smallest width unsigned integer Swift has is UInt8.

typealias Pointer = UInt8 // Also should be UInt4. In any case, we are not currently using this or Status.

typealias Status = UInt16 // Should be a UInt12 if we wanted exactly as many status bits as the HP-35.

// This is how many nibbles there are in a register:
let RegisterLength = 14

// This is how many of the nibbles are devoted to the exponent:
let ExponentLength = 3

// Two utilities for testing and display:
func nibbleFromCharacter(char: Character) -> Nibble {
    return Nibble(Int(String(char))!)
}

func hexCharacterFromNibble(nibble: Nibble) -> Character {
    return Character(String(format:"%1X", nibble))
}

// A register is 14 nibbles (56 bits). Mostly nibbles are used to represent the digits 0-9, but the leftmost one, nibble 13, corresponds to the sign of the mantissa, nibbles 12 to 3 inclusive represent 10 digits of mantissa, and nibbles 2 to 0 represent the exponent.
struct Register {
    var nibbles: [Nibble] = [Nibble](count:RegisterLength, repeatedValue: UInt8(0))
    
    // Hmmm. It seems I need the empty initializer because I created init(fromDecimalString:).
    init() {}
    
    // Initialize a register from a fourteen-digit decimal string (e.g., "91250000000902")
    init(fromDecimalString: String) {
        let characters = Array(fromDecimalString.characters)
        assert(RegisterLength == characters.count)
        var characterIdx = 0
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let char: Character = characters[characterIdx]
            nibbles[nibbleIdx] = nibbleFromCharacter(char)
            characterIdx += 1
            nibbleIdx -= 1
        }
    }
    
    func asDecimalString() -> String {
        var digits: String = ""
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let nibble = nibbles[nibbleIdx]
            let hexChar = hexCharacterFromNibble(nibble)
            digits.append(hexChar)
            nibbleIdx -= 1
        }
        return digits
    }
    
    mutating func setNibble(index: Int, value: Nibble) {
        nibbles[index] = value
    }
}

class CPUState {
    
    // The singleton starts in the traditional state that an HP-35 is in when you power it on.
    // The display just shows 0 and a decimal point.
    static let sharedInstance = CPUState(decimalStringA: "00000000000000", decimalStringB: "02999999999999")
    
    var registers = [Register](count:7, repeatedValue:Register())
    
    // All the important initialization is done above when registers is assigned.
    init() {}
    
    // A method provided prinicipally for testing. Allows the state of the registers that record user input to be
    // initialized from decimal strings. Register C will be canonicalized from registers A and B. The remaining
    // registers will be initialized to zeros.
    init(decimalStringA: String, decimalStringB: String) {
        let registerA = Register(fromDecimalString: decimalStringA)
        let registerB = Register(fromDecimalString: decimalStringB)
        
        registers[RegId.A.rawValue] = registerA
        registers[RegId.B.rawValue] = registerB
        //      LEARN LATER
        registers[RegId.C.rawValue] = registerA
        canonicalize()
    }
    
    // Computes and stores into register C whatever is currently showing to the user in A and B. Note that it
    // is possible for canonicalization to fail. For example 123.4567890 99 overflows when canonicalized. When it
    // fails due to overflow (or underflow), registers A and B are overwritten with overflow (or underflow) values.
    //
    // This function is unimplemented. I hard-coded in a value that will make the first of the five test cases pass.
    //
    // When you are done re-implementing this method, all five test cases should pass (and any other test cases
    // that obey the rules described in comments at the top of DisplayDecoder.swift should also pass).
    //
    // Make use of the enums RegisterASpecialValues and RegisterBSpecialValues so that you don't have to hard
    // code "2" to mean a decimal point (similarly for the other special values).
    func canonicalize() {
        
        var registerC = Register(fromDecimalString: "00000000000000")
        
        let nibblesA = registers[RegId.A.rawValue].nibbles
        let nibblesB = registers[RegId.B.rawValue].nibbles
        
        let exponentIsPositive = nibblesA[2] != RegisterASpecialValues.Minus.rawValue
        
        // Just copy over the mantissa sign
        registerC.setNibble(13, value: nibblesA[13])
        
        // Build up the exponent from register A (already have the sign)
        // Examine nibbles 1 and 0
        var exponent = Int(nibblesA[1] * 10 + nibblesA[0])
        
        var decimalPosition = 0
        var leadingDigitPosition = 1
        
        var exponentAdjustment = 0
        
        for var idx = 12; idx >= 3; idx -= 1 {
            // do a test to see if register B the decimal point has been found
            if nibblesB[idx] == 2 {
                exponentAdjustment += 1
                break
            }
                // if true , break out of the loop
            else {
                decimalPosition += 1
            }
        }
        
        for var idx = 12; idx >= 3; idx -= 1 {
            if nibblesA[idx] > 0 {
                leadingDigitPosition += 1
            }
            
            exponentAdjustment = leadingDigitPosition - decimalPosition
            
            
            var finalExponent = 0
            
            if !exponentIsPositive {
                finalExponent += exponent
            } else {
                finalExponent += (100 - exponent)}
            
            var newString = nibblesA
            
            //        if finalExponent > 99 {
            //                overflow(true)
            //        } else {
            //            finalExponent < -99{
            //                underflow()
            //from here you would implement this exponent component, as well as the digit, positive/negative components, and
        // place this information into Register C.
        
    }
    registers[RegId.C.rawValue] = registerC
    
    
    
    
    
    // Displays positive or negative overflow value
    func overflow(positive: Bool) {
        registers[RegId.A.rawValue] = Register(fromDecimalString: positive ? "09999999999099" : "99999999999099")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02000000000000")
        canonicalize()
    }
    
    // Displays underflow value
    func underflow() {
        registers[RegId.A.rawValue] = Register(fromDecimalString: "00000000000000")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02999999999999")
        canonicalize()
    }
    
    func decimalStringForRegister(regId: RegId) -> String {
        let register = registers[regId.rawValue]
        return register.asDecimalString()
    }
    
}
}


enum RegId: Int {
    case A = 0 // General Purpose (math or scratchpad)
    case B = 1 // General Purpose (math or scratchpad)
    case C = 2 // X Register
    case D = 3 // Y Register
    case E = 4 // Z Register
    case F = 5 // T (top or trigonemtric) Register
    case M = 6 // Scratchpad (like A and B, but no math)
    }
