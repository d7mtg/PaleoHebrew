import SwiftUI

struct PaleoLetter {
    let paleo: String
    let modern: String
    let name: String
}

// Sample data:
let paleoLetters: [PaleoLetter] = [
    PaleoLetter(paleo: "𐤀", modern: "א", name: "Aleph"),
    PaleoLetter(paleo: "𐤁", modern: "ב", name: "Bet"),
    PaleoLetter(paleo: "𐤂", modern: "ג", name: "Gimel"),
    PaleoLetter(paleo: "𐤃", modern: "ד", name: "Dalet"),
    PaleoLetter(paleo: "𐤄", modern: "ה", name: "He"),
    PaleoLetter(paleo: "𐤅", modern: "ו", name: "Vav"),
    PaleoLetter(paleo: "𐤆", modern: "ז", name: "Zayin"),
    PaleoLetter(paleo: "𐤇", modern: "ח", name: "Chet"),
    PaleoLetter(paleo: "𐤈", modern: "ט", name: "Tet"),
    PaleoLetter(paleo: "𐤉", modern: "י", name: "Yod"),
    PaleoLetter(paleo: "𐤊", modern: "כ", name: "Kaf"),
    PaleoLetter(paleo: "𐤋", modern: "ל", name: "Lamed"),
    PaleoLetter(paleo: "𐤌", modern: "מ", name: "Mem"),
    PaleoLetter(paleo: "𐤍", modern: "נ", name: "Nun"),
    PaleoLetter(paleo: "𐤎", modern: "ס", name: "Samekh"),
    PaleoLetter(paleo: "𐤏", modern: "ע", name: "Ayin"),
    PaleoLetter(paleo: "𐤐", modern: "פ", name: "Pe"),
    PaleoLetter(paleo: "𐤑", modern: "צ", name: "Tsadi"),
    PaleoLetter(paleo: "𐤒", modern: "ק", name: "Qof"),
    PaleoLetter(paleo: "𐤓", modern: "ר", name: "Resh"),
    PaleoLetter(paleo: "𐤔", modern: "ש", name: "Shin"),
    PaleoLetter(paleo: "𐤕", modern: "ת", name: "Tav")
]
