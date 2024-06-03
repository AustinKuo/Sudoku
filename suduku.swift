import Foundation
import Glibc


let DEBUG = true
let TRACE = false

let DEBUG_BREAK = false
let DEBUG_TIMES = 1

let SHOWCANDLISTNUM = [0]

let USE_NARROW_METHOD_1 = true //Hidden Single
let USE_NARROW_METHOD_2 = true
let USE_NARROW_METHOD_3 = true
let USE_NARROW_METHOD_4 = true //Three dimension
let USE_NARROW_METHOD_5 = true
let USE_NARROW_METHOD_6 = true //Double Same Number
let USE_NARROW_METHOD_7 = true //Double Chain
let USE_NARROW_METHOD_8 = true //Trapezoid
let USE_GUESS_NUMBER = false //Unfinished

typealias ReturnCode = Int

var SUCCESS: ReturnCode = 1
var FAIL: ReturnCode = 0
var ERROR: ReturnCode = -1

let BlockNumber = 3
let ColNumber = 9
let RowNumber = ColNumber
let NumberOfSudoku = RowNumber * ColNumber
let CandListCol = 2
let CandListRow = 5
let NumNarMehod2 = 3
let NumNarMehod4 = 3
let NumNarMehod6 = 2
let NumNarMehod7 = 2
let NumNarMehod8 = 2
let MinQuxNumber = 60

func DEBUG_LOG(_ toPrintStr: String, line: Int = #line) {
    if DEBUG {
        print("(\(line)): \(toPrintStr)")
    }
}

func TRACE_LOG(_ toPrintStr: String, function: String = #function, line: Int = #line) {
    if TRACE {
        print("\(function)(\(line)): \(toPrintStr)")
    }
}


class NumState {
    private var column:Int
    private var row:Int

    private var number:Int = 0
    private var haveAnswer:Bool = false
    private var isQuest:Bool = false
    private var iterFlag = false

    private var candAnsList:Set<Int>

    init (_ column: Int, _ row: Int) {
        self.column = column
        self.row = row

        self.candAnsList = Set<Int>()
    }

    convenience init (_ column: Int, _ row: Int, number: Int) {
        self.init(column, row)

        self.number = number
        self.isQuest = true
    }

    convenience init (_ numState: NumState) {
        let number = numState.getNumber()

        if number == 0 { self.init(numState.column, numState.row) }
        else { self.init(numState.column, numState.row, number: number) }
    }

    @discardableResult func setAnswer (_ answer: Int) -> Bool {
        if haveAnswer { return false }

        number = answer
        haveAnswer = true
        candAnsList.removeAll()

        return true
    }

    @discardableResult func resetAnswer() -> Bool {
        if !haveAnswer { return false }

        number = 0
        haveAnswer = false

        return true
    }

    @discardableResult func removeFromCand(_ number: Int) -> Bool {
        if !candAnsList.contains(number) { return false }
        candAnsList.remove(number)

        return true
    }

    func setIterFlag(_ bool: Bool) {
        iterFlag = bool
    }

    func isIter() -> Bool {
        return iterFlag
    }

    func getNumber() -> Int {
        return number
    }

    func addToCand(_ number: Int) {
        candAnsList.insert(number)
    }

    func getCandFirst() -> Int? {
        return candAnsList.first
    }

    func getCandCount() -> Int {
        return candAnsList.count
    }

    func containInCand(_ cmpNum: Int) -> Bool {
        if !isUnknown() { return false }
        return candAnsList.contains(cmpNum)
    }

    func containInCand(_ cmpNum: NumState) -> Bool {
        if !isUnknown() || candAnsList.count < cmpNum.getCandCount() {
            return false
        }
        for number in cmpNum.getCandList() {
            if !candAnsList.contains(number) { return false }
        }
        return true
    }

    func compareCand(_ cmpNum: NumState) -> Bool {
        let cmpCand = cmpNum.getCandList()
        if candAnsList.count != cmpCand.count { return false }
        for cmpNum in candAnsList {
            if !cmpCand.contains(cmpNum) { return false }
        }

        return true
    }

    func getCandList() -> Set<Int> {
        return Set(candAnsList)
    }

    func getPosition() -> (column: Int, row: Int) {
        return (column+1, row+1)
    }

    func isAnswered() -> Bool {
        return haveAnswer
    }

    func isQuestNum() -> Bool {
        return isQuest
    }

    func isUnknown() -> Bool {
        return !(haveAnswer || isQuest)
    }

    func isSame(as numCmp: NumState) -> Bool {
        return self.column == numCmp.column && self.row == numCmp.row
    }

    func isSameCol(_ cmpNum: NumState) -> Bool {
        return !self.isSame(as: cmpNum) && self.column == cmpNum.column
    }

    func isSameRow(_ cmpNum: NumState) -> Bool {
        return !self.isSame(as: cmpNum) && self.row == cmpNum.row
    }

    func isSameBlock(_ cmpNum: NumState) -> Bool {
        if self.isSame(as: cmpNum) { return false }
        return self.column/3 == cmpNum.column/3 && self.row/3 == cmpNum.row/3
    }

    func isSameCand(_ cmpNum: NumState) -> Bool {
        if  self.isSame(as: cmpNum) ||
            self.getCandCount() != cmpNum.getCandCount() {
            return false
        }

        for num in cmpNum.getCandList() {
            if !candAnsList.contains(num) { return false }
        }

        return true
    }

    func isCmpTarget(_ cmpNum: NumState) ->Bool {
        return isSameCol(cmpNum) || isSameRow(cmpNum) || isSameBlock(cmpNum)
    }
}

class SudokuState {

}

class SudokuMethod {
    private var sudokuList = [NumState]()

    init?(_ sudoku: [[Int]]) {
        for (col, colArray) in sudoku.enumerated() {
            for (row, number) in colArray.enumerated() {
                if  ![1, 2, 3, 4, 5, 6, 7, 8, 9].contains(number) {
                    self.sudokuList.append(NumState(col, row))
                } else {
                    self.sudokuList.append(NumState(col, row, number: number))
                }
            }
        }

        if let errorNum = self.checkIllegalPuzzle() {
            if DEBUG {
                let pos = errorNum.getPosition()
                print("ERROR! Column:\(pos.column), Rol:\(pos.row), Number:\(errorNum.getNumber())")
            }
            return nil
        }

        if !createCandAnsList() || !checkMultiSol() { return nil }
    }

    init?(_ suduku: [NumState]) {

        for numState in suduku {
            self.sudokuList.append(NumState(numState))
        }

        if let errorNum = self.checkIllegalPuzzle() {
            if DEBUG {
                let pos = errorNum.getPosition()
                print("ERROR! Column:\(pos.column), Rol:\(pos.row), Number:\(errorNum.getNumber())")
            }
            return nil
        }

        if !createCandAnsList() || !checkMultiSol() { return nil }
    }

    private func createCandAnsList() -> Bool {

        for numState in sudokuList {
            if !numState.isUnknown() { continue }

            nextTry: for tryNum in 1...ColNumber {
                if numState.containInCand(tryNum) { continue }
                for cmpNum in sudokuList {
                    if cmpNum.isCmpTarget(numState) && !cmpNum.isUnknown() {
                        if tryNum == cmpNum.getNumber() {
                            continue nextTry
                        }
                    }
                }
                numState.addToCand(tryNum)
            }

            if numState.getCandCount() == 0 {
                DEBUG_LOG("Can NOT get candidate answer list. ERROR!")
                return false
            }
        }

        return true
    }

    private func refreshCandAnsList(by targetNum: NumState) -> Bool{
        if !targetNum.isAnswered() { return false }

        let removeNum = targetNum.getNumber()
        for numState in sudokuList {
            if numState.isUnknown() && numState.isCmpTarget(targetNum) {
                numState.removeFromCand(removeNum)
                if numState.getCandCount() == 0 {
                    DEBUG_LOG("Can NOT refresh candidate answer list. ERROR!")
                    return false
                }
            }
        }

        return true

    }


    /* Single Answer */
    func methodFindAnswer1() -> Int {
        var numOfFindAns = 0

        for numState in sudokuList {
            if numState.getCandCount() != 1 { continue }
            if let num = numState.getCandFirst() {
                if !setNumber(in: numState, num) { return ERROR }
                numOfFindAns += 1
            }
        }

        return numOfFindAns
    }

    /* Hidden Single Answer */
    func methodFindAnswer2() -> Int {
        var numOfFindAns = 0

        for tryNum in 1...ColNumber {
            TRACE_LOG("+++Find answer of number \(tryNum) START+++")

            for numState in sudokuList {
                var colNoSameNum = true
                var rowNoSameNum = true
                var blockNoSameNum = true

                if !numState.containInCand(tryNum) {
                    continue
                }

                for cmpNum in sudokuList {
                    if !cmpNum.containInCand(tryNum) {
                        continue
                    }

                    if colNoSameNum && cmpNum.isSameCol(numState) {
                        colNoSameNum = false
                    }
                    if rowNoSameNum && cmpNum.isSameRow(numState) {
                        rowNoSameNum = false
                    }
                    if blockNoSameNum && cmpNum.isSameBlock(numState) {
                        blockNoSameNum = false
                    }

                    if !(colNoSameNum || rowNoSameNum || blockNoSameNum) {
                        break
                    }
                }

                if colNoSameNum || rowNoSameNum || blockNoSameNum {
                    if !setNumber(in: numState, tryNum) {
                        return ERROR
                    }
                    TRACE_LOG("Number:\(tryNum) on \(numState.getPosition())")
                    numOfFindAns += 1
                }
            }

            if TRACE {
                printSudoku()
            }
            TRACE_LOG("+++Find answer of number \(tryNum) END+++\n")
        }

        return numOfFindAns
    }

    func methodNarrowCandList1() -> Int {
        var narrowAns = 0

        for tryNum in 1...ColNumber {

            nextTry: for numState in sudokuList {
                var colSameNum = false
                var rowSameNum = false
                var blockSameNum = false

                var blockColSameNum = false
                var blockRowSameNum = false

                var blockColNar = false
                var blockRowNar = false

                if !numState.containInCand(tryNum) {
                    continue
                }

                for cmpNum in sudokuList {
                    if !cmpNum.containInCand(tryNum) ||
                        !cmpNum.isCmpTarget(numState) {
                        continue
                    }

                    if !cmpNum.isSameBlock(numState) {
                        if !colSameNum && cmpNum.isSameCol(numState) {
                            colSameNum = true
                        } else if !rowSameNum && cmpNum.isSameRow(numState) {
                            rowSameNum = true
                        }
                    } else if !blockSameNum {
                        if !blockColSameNum && cmpNum.isSameCol(numState) {
                            blockColSameNum = true
                        } else if !blockRowSameNum &&
                            cmpNum.isSameRow(numState) {
                            blockRowSameNum = true
                        } else {
                            blockSameNum = true
                        }
                        if (blockColSameNum && blockRowSameNum) {
                            blockSameNum = true
                        }
                    }
                    if colSameNum && rowSameNum && blockSameNum {
                        continue nextTry
                    }
                }

                if !colSameNum || (!blockSameNum && blockColSameNum) {
                    blockColNar = true
                } else if !rowSameNum || (!blockSameNum && blockRowSameNum) {
                    blockRowNar = true
                }

                for tarNum in sudokuList {
                    if !tarNum.containInCand(tryNum) ||
                        !tarNum.isCmpTarget(numState){
                        continue
                    }
                    if blockColNar && (tarNum.isSameCol(numState) !=
                        tarNum.isSameBlock(numState)) {
                        if tarNum.removeFromCand(tryNum) { narrowAns += 1 }
                    } else if blockRowNar && (tarNum.isSameRow(numState) !=
                        tarNum.isSameBlock(numState)) {
                        if tarNum.removeFromCand(tryNum) { narrowAns += 1 }
                    }

                    if tarNum.getCandCount() == 0 { return ERROR }
                }
            }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 1.")
        return narrowAns
    }

    func methodNarrowCandList2() -> Int {
        var narrowAns = 0

        for (i, numState) in sudokuList.enumerated() {
            if !numState.isUnknown() || numState.getCandCount() > NumNarMehod2 {
                continue
            }
            TRACE_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")

            var candListCol = numState.getCandList()
            var candListRow = numState.getCandList()
            var candListBlock = numState.getCandList()

            var numListCol = [numState]
            var numListRow = [numState]
            var numListBlock = [numState]

            var numberList: Set<Int>
            var targetList: [NumState]
            let isSame: (NumState, NumState) -> Bool

            for (j, cmpNum) in sudokuList.enumerated() {
                if i <= j || !cmpNum.isUnknown() ||
                    !cmpNum.isCmpTarget(numState) {
                    continue
                }

                if cmpNum.isSameCol(numState) {
                    var candList = candListCol
                    for num in cmpNum.getCandList() {
                        if !candList.contains(num) {
                            candList.insert(num)
                        }
                    }
                    if candList.count <= NumNarMehod2 {
                        candListCol = candList
                        numListCol.append(cmpNum)
                    }
                }

                if cmpNum.isSameRow(numState) {
                    var candList = candListRow
                    for num in cmpNum.getCandList() {
                        if !candList.contains(num) {
                            candList.insert(num)
                        }
                    }
                    if candList.count <= NumNarMehod2 {
                        candListRow = candList
                        numListRow.append(cmpNum)
                    }
                }

                if cmpNum.isSameBlock(numState) {
                    var candList = candListBlock
                    for num in cmpNum.getCandList() {
                        if !candList.contains(num) {
                            candList.insert(num)
                        }
                    }
                    if candList.count <= NumNarMehod2 {
                        candListBlock = candList
                        numListBlock.append(cmpNum)
                    }
                }
            }

            if numListCol.count == NumNarMehod2 {
                numberList = candListCol
                targetList = numListCol
                isSame = {
                    (num1: NumState, num2: NumState) -> Bool in
                    return num1.isSameCol(num2)
                }
            } else if numListRow.count == NumNarMehod2 {
                numberList = candListRow
                targetList = numListRow
                isSame = {
                    (num1: NumState, num2: NumState) -> Bool in
                    return num1.isSameRow(num2)
                }
            } else if numListBlock.count == NumNarMehod2 {
                numberList = candListBlock
                targetList = numListBlock
                isSame = {
                    (num1: NumState, num2: NumState) -> Bool in
                    return num1.isSameBlock(num2)
                }
            } else {
                continue
            }

            nextTry: for tarNum in sudokuList {
                if !tarNum.isUnknown() { continue }
                for cmpNum in targetList {
                    if !isSame(cmpNum, tarNum) { continue nextTry }
                }

                for number in numberList {
                    TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                    if tarNum.removeFromCand(number) { narrowAns += 1 }
                }

                if tarNum.getCandCount() == 0 { return ERROR }
            }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 2.")
        return narrowAns
    }

    func methodNarrowCandList3() -> Int {
        var narrowAns = 0

        let removeFromList = {
            (listDic: [Int: [NumState]]) -> Int in
            var narrowAns = 0
            for (tryNum, numList) in listDic {
                var tryNumSta:NumState
                if let num = numList.first, numList.count == 1 {
                    tryNumSta = num
                } else { continue }

                for (cmpNum, cmpList) in listDic {
                    if tryNum == cmpNum { continue }

                    var cmpNumSta:NumState
                    if let num = cmpList.first, cmpList.count == 1 {
                        cmpNumSta = num
                    } else { continue }

                    if cmpNumSta.isSame(as: tryNumSta) {
                        for rmNum in cmpNumSta.getCandList() {
                            if rmNum != tryNum && rmNum != cmpNum {
                                if cmpNumSta.removeFromCand(rmNum) {
                                    narrowAns += 1
                                }
                            }
                        }

                        for rmNum in tryNumSta.getCandList() {
                            if rmNum != tryNum && rmNum != cmpNum {
                                if cmpNumSta.removeFromCand(rmNum) {
                                    narrowAns += 1
                                }
                            }
                        }
                        if cmpNumSta.getCandCount() == 0 ||
                            tryNumSta.getCandCount() == 0 {
                            return ERROR
                        }
                    }
                }
            }
            return narrowAns
        }

        for numState in sudokuList {
            if !numState.isUnknown() {
                continue
            }

            var colListDic = [Int: [NumState]]()
            var rowListDic = [Int: [NumState]]()
            var blockListDic = [Int: [NumState]]()

            let numCandList = numState.getCandList()

            reTry: for tryNum in numCandList {

                for cmpNum in sudokuList {
                    if !cmpNum.containInCand(tryNum) {
                        continue
                    }

                    if cmpNum.isSameCol(numState) {
                        if var list = colListDic[tryNum] {
                            list.append(cmpNum)
                            colListDic[tryNum] = list
                        } else {
                            colListDic[tryNum] = [cmpNum]
                        }
                    }

                    if cmpNum.isSameRow(numState) {
                        if var list = rowListDic[tryNum] {
                            list.append(cmpNum)
                            rowListDic[tryNum] = list
                        } else {
                            rowListDic[tryNum] = [cmpNum]
                        }
                    }

                    if cmpNum.isSameBlock(numState) {
                        if var list = blockListDic[tryNum] {
                            list.append(cmpNum)
                            blockListDic[tryNum] = list
                        } else {
                            blockListDic[tryNum] = [cmpNum]
                        }
                    }
                }
            }

            narrowAns += removeFromList(colListDic)
            narrowAns += removeFromList(rowListDic)
            narrowAns += removeFromList(blockListDic)
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 3.")
        return narrowAns
    }

    func methodNarrowCandList4() -> Int {
        var narrowAns = 0

        let checkListCnt = {
            (numList: inout [Int: [NumState]]) in
            for (key, list) in numList {
                if list.count > NumNarMehod4 {
                    numList[key] = nil
                }
            }
        }

        let process = {
            (numList: [Int: [NumState]], rvNum: Int, isCol: Bool) -> Int in
            var narrows = 0
            let getKey: (NumState) -> Int
            let getSubKey: (NumState) -> Int

            if isCol {
                getKey = { (num: NumState) -> Int in
                            return num.getPosition().column
                }
                getSubKey = { (num: NumState) -> Int in
                            return num.getPosition().row
                }
            } else {
                getKey = { (num: NumState) -> Int in
                            return num.getPosition().row
                }
                getSubKey = { (num: NumState) -> Int in
                            return num.getPosition().column
                }
            }

            for (iKey, iList) in numList {
                var iNumList = Set<Int>()
                for numState in iList {
                    iNumList.insert(getSubKey(numState))
                }

                for (jKey, jList) in numList {
                    if jKey == iKey { continue }

                    var jNumList = Set(iNumList)
                    for numState in jList {
                        jNumList.insert(getSubKey(numState))
                    }

                    if jNumList.count > NumNarMehod4 { continue }


                    for (kKey, kList) in numList {
                        if kKey == iKey || kKey == jKey { continue }

                        var kNumList = Set(jNumList)
                        for numState in kList {
                            kNumList.insert(getSubKey(numState))
                        }

                        if kNumList.count > NumNarMehod4 { continue }

                        for tarNum in self.sudokuList {
                            if !tarNum.isUnknown() { continue }

                            let tarKey = getKey(tarNum)
                            let tarSubKey = getSubKey(tarNum)

                            if  kNumList.contains(tarSubKey) &&
                                tarKey != iKey &&
                                tarKey != jKey &&
                                tarKey != kKey &&
                                tarNum.removeFromCand(rvNum) {
                                TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                                narrows += 1
                            }

                            if tarNum.getCandCount() == 0 { return ERROR }
                        }
                    }
                }
            }

            return narrows
        }

        for tryNum in 1...RowNumber {
            var ret = 0

            var colNumList = [Int: [NumState]]()
            var rowNumList = [Int: [NumState]]()

            TRACE_LOG("tryNum = \(tryNum)")

            for numState in sudokuList {
                if  !numState.isUnknown() ||
                    !numState.containInCand(tryNum) {
                    continue
                }

                let colPos = numState.getPosition().column
                let rowPos = numState.getPosition().row

                if var list = colNumList[colPos] {
                    list.append(numState)
                    colNumList[colPos] = list
                } else {
                    colNumList[colPos] = [numState]
                }

                if var list = rowNumList[rowPos] {
                    list.append(numState)
                    rowNumList[rowPos] = list
                } else {
                    rowNumList[rowPos] = [numState]
                }
            }

            checkListCnt(&colNumList)
            checkListCnt(&rowNumList)

            ret = process(colNumList, tryNum, true)
            if ret == ERROR { return ret }
            else { narrowAns += ret }

            ret = process(rowNumList, tryNum, false)
            if ret == ERROR { return ret }
            else { narrowAns += ret }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 4.")
        return narrowAns
    }

    func methodNarrowCandList5() -> Int {
        var narrowAns = 0

        for tryNum in 1...RowNumber {
            nextTry: for numState in sudokuList {
                // if !numState.isUnknown() { continue }

                var sameBlockCol = false
                var sameBlockRow = false
                var colSameRowNum:NumState?
                var rowSameColNum:NumState?
                var colSameTarget = true
                var rowSameTarget = true

                for cmpNum in sudokuList {
                    if cmpNum.isSame(as: numState) ||
                        !cmpNum.containInCand(tryNum) {
                        continue
                    }
                    if cmpNum.isSameBlock(numState) {
                        if cmpNum.isSameCol(numState) {
                            sameBlockCol = true
                        } else if cmpNum.isSameRow(numState) {
                            sameBlockRow = true
                        } else {
                            continue nextTry
                        }
                    } else {
                        if cmpNum.isSameCol(numState) && colSameTarget {
                            if colSameRowNum == nil {
                                colSameRowNum = cmpNum
                            } else { colSameTarget = false }
                        } else if cmpNum.isSameRow(numState) && rowSameTarget {
                            if rowSameColNum == nil {
                                rowSameColNum = cmpNum
                            } else { rowSameTarget = false }
                        }
                    }

                    if !colSameTarget && !rowSameTarget {
                        continue nextTry
                    }
                }

                if colSameRowNum == nil && rowSameColNum == nil ||
                    !sameBlockCol || !sameBlockRow { continue }

                colProc: while colSameTarget, let baseNum = colSameRowNum {
                    var cmpBaseNum:NumState?
                    let targetCol:Int
                    let targetRow:Int

                    for cmpNum in sudokuList {
                        if cmpNum.containInCand(tryNum) &&
                            cmpNum.isSameRow(baseNum) {
                            if cmpBaseNum != nil { break colProc }
                            cmpBaseNum = cmpNum
                        }
                    }

                    if let cmpBase = cmpBaseNum {
                        if cmpBase.isSameBlock(baseNum) { break colProc }

                        targetRow = numState.getPosition().row
                        targetCol = cmpBase.getPosition().column
                    } else { break colProc }

                    if let tarNum = getNumFromPos(targetCol, targetRow) {
                        if tarNum.isUnknown() && tarNum.containInCand(tryNum) {
                            TRACE_LOG("tryNum = \(tryNum)")
                            TRACE_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")
                            TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")

                            if tarNum.removeFromCand(tryNum) {
                                narrowAns += 1
                            }

                            if tarNum.getCandCount() == 0 { return ERROR }
                        }
                    } else {
                        DEBUG_LOG("Can NOT find Number.\nBREAK")
                        return ERROR
                    }

                    break
                }

                rowProc: while rowSameTarget, let baseNum = rowSameColNum {
                    var cmpBaseNum:NumState?
                    let targetCol:Int
                    let targetRow:Int

                    for cmpNum in sudokuList {
                        if cmpNum.containInCand(tryNum) &&
                            cmpNum.isSameCol(baseNum) {
                            if cmpBaseNum != nil { break rowProc }
                            cmpBaseNum = cmpNum
                        }
                    }

                    if let cmpBase = cmpBaseNum {
                        if cmpBase.isSameBlock(baseNum) { break rowProc }

                        targetRow = cmpBase.getPosition().row
                        targetCol = numState.getPosition().column
                    } else { break rowProc }

                    if let tarNum = getNumFromPos(targetCol, targetRow) {
                        if tarNum.isUnknown() && tarNum.containInCand(tryNum) {
                            TRACE_LOG("tryNum = \(tryNum)")
                            TRACE_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")
                            TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                            if tarNum.removeFromCand(tryNum) {
                                narrowAns += 1
                            }

                            if tarNum.getCandCount() == 0 { return ERROR }
                        }
                    } else {
                        DEBUG_LOG("Can NOT find Number.\nBREAK")
                        return ERROR
                    }

                    break
                }
            }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 5.")
        return narrowAns
    }

    func methodNarrowCandList6() -> Int {
        var narrowAns = 0
        var layer = 0
        var cmpStateList = [Int: NumState]()

        let isContain = {
            (cmpNum: NumState) -> (Int, NumState) -> Bool in
            func contain (_: Int, _ numState: NumState) -> Bool {
                if numState.isSame(as: cmpNum) { return true }
                else { return false }
            }
            return contain
        }

        func findNext(_ numState: NumState, _ refNumState: NumState) -> Int {
            var narrow = 0

            // Layer up
            layer += 1
            cmpStateList[layer] = refNumState

            for cmpNum in self.sudokuList {
                if  !cmpNum.isUnknown() ||
                    !cmpNum.isCmpTarget(refNumState) ||
                    !cmpNum.isSameCand(refNumState) ||
                    cmpStateList.contains(where: isContain(cmpNum)) {
                    continue
                }

                // TODO: Limit for online compiler
                if layer > 7 { break }

                TRACE_LOG("cmpNum: \(cmpNum.getPosition()), \(cmpNum.getCandList())")

                if layer % 2 == 1 {
                    for tarNum in self.sudokuList {

                        if  !tarNum.isUnknown() ||
                            !tarNum.isCmpTarget(cmpNum) ||
                            !tarNum.isCmpTarget(numState) {
                            continue
                        }

                        for rvNum in numState.getCandList() {
                            if tarNum.removeFromCand(rvNum) {
                                TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                                narrow += 1
                            }

                            if tarNum.getCandCount() == 0 { return ERROR }
                        }
                    }
                }

                let ret = findNext(numState, cmpNum)
                if ret == ERROR  { return ERROR }
                else { narrow += ret }
            }

            // Layer down
            let rmNumState = cmpStateList.removeValue(forKey: layer)
            if rmNumState == nil { return ERROR }
            layer -= 1

            return narrow
        }

        for numState in sudokuList {
            if !numState.isUnknown() ||
                numState.getCandCount() != NumNarMehod6 {
                continue
            }
            TRACE_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")

            let ret = findNext(numState, numState)
            if ret == ERROR  { return ERROR }
            else { narrowAns += ret }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 6.")
        return narrowAns
    }

    func methodNarrowCandList7() -> Int {
        var narrowAns = 0
        var layer = 0
        var cmpStateList = [Int: NumState]()

        let isContain = {
            (cmpNum: NumState) -> (Int, NumState) -> Bool in
            func contain (_: Int, _ numState: NumState) -> Bool {
                if numState.isSame(as: cmpNum) { return true }
                else { return false }
            }
            return contain
        }

        func findNext(_ numState: NumState, _ refNumState: NumState,
                _ tarNum: Int, _ refNum: Int) -> Int {
            var narrow = 0

            // Layer up
            layer += 1
            cmpStateList[layer] = refNumState

            for cmpNum in self.sudokuList {
                var refNumber = 0       // The same number between ref and cmp
                var newNumber = 0       // The new number in numberList

                var refCandList: Set<Int>

                if  !cmpNum.isUnknown() ||
                    cmpNum.getCandCount() != NumNarMehod7 ||
                    !cmpNum.isCmpTarget(refNumState) ||
                    cmpStateList.contains(where: isContain(cmpNum)) {
                    continue
                }

                // TODO: Limit for online compiler
                if layer > 5 { break }

                TRACE_LOG("cmpNum: \(cmpNum.getPosition()), \(cmpNum.getCandList())")

                refCandList = cmpNum.getCandList()

                if let number = refCandList.remove(refNum) {
                    refNumber = number
                }

                if refNumber == 0 { continue }

                if let number = refCandList.first { newNumber = number }
                else { return ERROR }

                if newNumber == tarNum {
                    for tarNum in self.sudokuList {

                        if  !tarNum.isUnknown() ||
                            !tarNum.isCmpTarget(cmpNum) ||
                            !tarNum.isCmpTarget(numState) {
                            continue
                        }

                        if tarNum.removeFromCand(newNumber) {
                            TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                            narrow += 1
                        }

                        if tarNum.getCandCount() == 0 { return ERROR }
                    }
                } else {
                    let ret = findNext(numState, cmpNum, tarNum, newNumber)
                    if ret == ERROR  { return ERROR }
                    else { narrow += ret }
                }
            }

            // Layer down
            let rmNumState = cmpStateList.removeValue(forKey: layer)
            if rmNumState == nil { return ERROR }
            layer -= 1

            return narrow
        }

        for numState in sudokuList {
            var ret: Int

            if !numState.isUnknown() ||
                numState.getCandCount() != NumNarMehod7 {
                continue
            }
            TRACE_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")

            let numList = Array(numState.getCandList())

            ret = findNext(numState, numState, numList[0], numList[1])
            if ret == ERROR  { return ERROR }
            else { narrowAns += ret }

            ret = findNext(numState, numState, numList[1], numList[0])
            if ret == ERROR  { return ERROR }
            else { narrowAns += ret }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 7.")
        return narrowAns
    }

    func methodNarrowCandList8() -> Int {
        var narrowAns = 0

        let checkListCnt = {
            (numList: inout [Int: [NumState]]) in
            for (key, list) in numList {
                if list.count != NumNarMehod8 {
                    numList[key] = nil
                }
            }
        }

        let process = {
            (numList: [Int: [NumState]], rvNum: Int, isCol: Bool) -> Int in
            var narrows = 0
            let isSameSubKey: (NumState, NumState) -> Bool

            if isCol {
                isSameSubKey = { (num: NumState, cmpNum: NumState) -> Bool in
                    return num.isSameRow(cmpNum)
                }
            } else {
                isSameSubKey = { (num: NumState, cmpNum: NumState) -> Bool in
                    return num.isSameCol(cmpNum)
                }
            }

            for (iKey, iList) in numList {
                for (jKey, jList) in numList {
                    if jKey == iKey { continue }
                    var iTarNum: NumState?
                    var jTarNum: NumState?

                    for (i, iNumState) in iList.enumerated() {
                        for (j, jNumState) in jList.enumerated() {
                            if isSameSubKey(iNumState, jNumState) {
                                if i == 0 { iTarNum = iList[1] }
                                else { iTarNum = iList[0] }
                                if j == 0 { jTarNum = jList[1] }
                                else { jTarNum = jList[0] }
                                break
                            }
                        }
                    }

                    if iTarNum == nil || jTarNum == nil { continue }

                    for tarNum in self.sudokuList {
                        if  !tarNum.isUnknown() ||
                            !tarNum.isCmpTarget(iTarNum!) ||
                            !tarNum.isCmpTarget(jTarNum!) {
                            continue
                        }

                        if tarNum.removeFromCand(rvNum) {
                            TRACE_LOG("tarNum: \(tarNum.getPosition()), \(tarNum.getCandList())")
                            narrows += 1
                        }

                        if tarNum.getCandCount() == 0 { return ERROR }
                    }
                }
            }

            return narrows
        }

        for tryNum in 1...RowNumber {
            var ret = 0

            var colNumList = [Int: [NumState]]()
            var rowNumList = [Int: [NumState]]()

            TRACE_LOG("tryNum = \(tryNum)")

            for numState in sudokuList {
                if  !numState.isUnknown() ||
                    !numState.containInCand(tryNum) {
                    continue
                }

                let colPos = numState.getPosition().column
                let rowPos = numState.getPosition().row

                if var list = colNumList[colPos] {
                    list.append(numState)
                    colNumList[colPos] = list
                } else {
                    colNumList[colPos] = [numState]
                }

                if var list = rowNumList[rowPos] {
                    list.append(numState)
                    rowNumList[rowPos] = list
                } else {
                    rowNumList[rowPos] = [numState]
                }
            }

            checkListCnt(&colNumList)
            checkListCnt(&rowNumList)

            ret = process(colNumList, tryNum, true)
            if ret == ERROR { return ret }
            else { narrowAns += ret }

            ret = process(rowNumList, tryNum, false)
            if ret == ERROR { return ret }
            else { narrowAns += ret }
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Narrow Mehod 8.")
        return narrowAns
    }

    func methodGuessNumber() -> Int {
        var solverIns:SudokuMethod
        var tempSudoku = [NumState]()
        var sudokuArray = [[Int]]()
        var rowArray = [Int]()
        var ansCandList:[Int]
        var tempAns:NumState
        var minCount:Int
        var narrowAns = 0

        nextTry: while true {
            minCount = RowNumber

            for numState in sudokuList {
                rowArray.append(numState.getNumber())
                if numState.getPosition().row == RowNumber {
                    sudokuArray.append(rowArray)
                    rowArray.removeAll()
                }
            }
            for (col, colArray) in sudokuArray.enumerated() {
                for (row, number) in colArray.enumerated() {
                    if  ![1, 2, 3, 4, 5, 6, 7, 8, 9].contains(number) {
                        tempSudoku.append(NumState(col, row))
                    } else {
                        tempSudoku.append(NumState(col, row, number: number))
                    }
                }
            }

            tempAns = sudokuList[0]
            for numState in sudokuList {
                if !numState.isUnknown() || numState.isIter() { continue }
                if numState.getCandCount() < minCount {
                    minCount = numState.getCandCount()
                    tempAns = numState
                }
            }

            DEBUG_LOG("tempAns: \(tempAns.getPosition()), \(tempAns.getCandList())")

            ansCandList = Array(tempAns.getCandList())
            if ansCandList.count == 0 { return ERROR }

            let pos = tempAns.getPosition()
            tempAns = tempSudoku[(pos.column-1)*RowNumber + (pos.row-1)]

            for tryNumber in ansCandList {
                var ret:Int
                DEBUG_LOG("tryNumber = \(tryNumber)")

                if !setNumber(in: tempAns, tryNumber)  { return ERROR }
                if let ins = SudokuMethod(tempSudoku) { solverIns = ins }
                else { return ERROR }

                repeat {
                    ret = solverIns.methodNarrowCandList1()
                    if ret == ERROR { break }

                    ret = solverIns.methodNarrowCandList2()
                    if ret == ERROR { break }

                    ret = solverIns.methodNarrowCandList3()
                    if ret == ERROR { break }

                    ret = solverIns.methodNarrowCandList4()
                    if ret == ERROR { break }

                    ret = solverIns.methodNarrowCandList5()
                    if ret == ERROR { break }

                    ret = solverIns.methodNarrowCandList6()
                    if ret == ERROR { break }

                    ret = solverIns.methodFindAnswer1()
                    if ret == ERROR { break }

                    ret = solverIns.methodFindAnswer2()
                } while false

                if !resetNumber(from: tempAns) { return ERROR }

                if ret == ERROR {

                    let pos = tempAns.getPosition()
                    if let numState = getNumFromPos(pos.column, pos.row) {
                        numState.removeFromCand(tryNumber)
                        narrowAns += 1
                        DEBUG_LOG("numState: \(numState.getPosition()), \(numState.getCandList())")
                    } else { return ERROR }

                    break nextTry;
                }

                // print("Before:")
                // printCand()
                // if !resetNumber(from: tempAns) { return ERROR }
                // print("After")
                // printCand()
                // return ERROR
            }

            tempAns.setIterFlag(true)
        }

        TRACE_LOG("Narrowed \(narrowAns) answers by Guess Number Mehod.")
        return narrowAns
    }

    func setNumber(in targetnum: NumState, _ number: Int) -> Bool {
        targetnum.setAnswer(number)
        return refreshCandAnsList(by: targetnum)
    }

    func resetNumber(from targetnum: NumState) -> Bool {
        targetnum.resetAnswer()
        return createCandAnsList()
    }


    func getNumOfUnknown() -> Int {
        var numOfUnknown = 0
        for numState in sudokuList {
            if numState.isUnknown() { numOfUnknown += 1 }
        }

        return numOfUnknown
    }

    func getNumFromPos(_ col: Int, _ row: Int) -> NumState? {
        for numState in sudokuList {
            let pos = numState.getPosition()
            if pos.column == col && pos.row == row { return numState }
        }

        return nil
    }

    func getNumStateList() -> [NumState] {
        return sudokuList
    }

    func checkMultiSol() -> Bool {
        var questNumList = [NumState]()
        var kindNumList = [Int]()

        for numState in sudokuList {
            if numState.isQuestNum() { questNumList.append(numState) }
        }

        if questNumList.count < 17 { return false }

        for questNum in questNumList {
            let num = questNum.getNumber()

            if !kindNumList.contains(num) { kindNumList.append(num) }
        }
        if kindNumList.count < 7 { return false }

        //TODO

        return true
    }

    func checkIllegalPuzzle() -> NumState? {

        for numState in sudokuList {
            if numState.isUnknown() { continue }

            for cmpNumber in sudokuList {
                if  !cmpNumber.isUnknown() &&
                    cmpNumber.isCmpTarget(numState) &&
                    cmpNumber.getNumber() == numState.getNumber() {
                    return numState
                }
            }
        }

        return nil
    }

    func printSudoku() {
        print("┌---┬---┬---┬-┬---┬---┬---┬-┬---┬---┬---┐")
        print("│", terminator: "")
        for (count, numState) in sudokuList.enumerated() {
            if count > 0 {
                if count % RowNumber == 0 {
                    print("├---┼---┼---┼-┼---┼---┼---┼-┼---┼---┼---┤")
                }
                if count % (RowNumber * BlockNumber) == 0 {
                    print("├---┼---┼---┼-┼---┼---┼---┼-┼---┼---┼---┤")
                }
                if count % RowNumber == 0 {
                    print("│", terminator: "")
                } else if count % BlockNumber == 0 {
                    print(" │", terminator: "")
                }
            }

            if numState.isUnknown() {
                print("  ", terminator: " │")
            } else {
                print(" \(numState.getNumber())", terminator: " │")
            }

            if count % RowNumber == RowNumber - 1 {
                print()
            }
        }
        print("└---┴---┴---┴-┴---┴---┴---┴-┴---┴---┴---┘")
    }

    func printCand(_ numArray: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]) {
        let filter:[Int]

        if numArray.count == 0 || numArray[0] == 0 {
            filter = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        } else if numArray.count > RowNumber { return }
        else { filter = numArray }

        for char in filter {
            if ![1, 2, 3, 4, 5, 6, 7, 8, 9].contains(char) { return }
        }
        print("┌-------┬-------┬-------┬-┬-------┬-------┬-------┬-┬-------┬-------┬-------┐")
        for colIndex in 1...ColNumber {
            for rowIndex in 1...BlockNumber {
                print("│", terminator: "")
                for index in (colIndex-1)*RowNumber..<colIndex*RowNumber {
                    let numState = sudokuList[index]

                    if index % BlockNumber == 0 && index % RowNumber != 0 {
                        print(" │", terminator: "")
                    }

                    for i in 1+(rowIndex-1)*BlockNumber...rowIndex*BlockNumber {
                        if numState.containInCand(i) && filter.contains(i) {
                            print("\(i)", terminator: "")
                        } else { print(" ", terminator: "") }

                        if i % BlockNumber != 0 { print(terminator: "  ") }
                    }

                    print("│", terminator: "")
                }
                print()
            }

            if colIndex != ColNumber {
                print("├-------┼-------┼-------┼-┼-------┼-------┼-------┼-┼-------┼-------┼-------┤")
                if colIndex % BlockNumber == 0 {
                    print("├-------┼-------┼-------┼-┼-------┼-------┼-------┼-┼-------┼-------┼-------┤")
                }
            } else {
                print("└-------┴-------┴-------┴-┴-------┴-------┴-------┴-┴-------┴-------┴-------┘")
            }
        }
    }

    func printSudokuNumber() {
        for (i, num) in sudokuList.enumerated() {
            if (i % RowNumber == 0) { print() }

            if num.getNumber() != 0 { print(num.getNumber(), terminator: "") }
            else { print(0, terminator: "") }
        }
        print()
        print()
    }
}

class Sudoku {
    enum Method {
        case NARROW_METHOD_1
        case NARROW_METHOD_2
        case NARROW_METHOD_3
        case NARROW_METHOD_4
        case NARROW_METHOD_5
        case NARROW_METHOD_6
        case NARROW_METHOD_7
        case NARROW_METHOD_8
        case GUESS_NUMBER
    }

    private var USE_NARROW_METHOD_1 = false
    private var USE_NARROW_METHOD_2 = false
    private var USE_NARROW_METHOD_3 = false
    private var USE_NARROW_METHOD_4 = false
    private var USE_NARROW_METHOD_5 = false
    private var USE_NARROW_METHOD_6 = false
    private var USE_NARROW_METHOD_7 = false
    private var USE_NARROW_METHOD_8 = false
    private var USE_GUESS_NUMBER = false

    private var mainSolver:SudokuMethod

    init?(_ sudoku: [[Int]]) {
        if let ins = SudokuMethod(sudoku) { mainSolver = ins }
        else { return nil }
    }

    private func checkAnswer() -> (column: Int, row: Int, number: Int)? {
        if let errorNum = mainSolver.checkIllegalPuzzle() {
            let pos = errorNum.getPosition()
            return (pos.column, pos.row, errorNum.getNumber())
        } else {
            return nil
        }
    }

    // TODO: print -> DEBUG_LOG
    func setUseMethod(_ method: Method, _ methodSwitch: Bool) {
        switch method {
            case .NARROW_METHOD_1:
                self.USE_NARROW_METHOD_1 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 1.") }
            case .NARROW_METHOD_2:
                self.USE_NARROW_METHOD_2 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 2.") }
            case .NARROW_METHOD_3:
                self.USE_NARROW_METHOD_3 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 3.") }
            case .NARROW_METHOD_4:
                self.USE_NARROW_METHOD_4 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 4.") }
            case .NARROW_METHOD_5:
                self.USE_NARROW_METHOD_5 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 5.") }
            case .NARROW_METHOD_6:
                self.USE_NARROW_METHOD_6 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 6.") }
            case .NARROW_METHOD_7:
                self.USE_NARROW_METHOD_7 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 7.") }
            case .NARROW_METHOD_8:
                self.USE_NARROW_METHOD_8 = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Narrow Method 8.") }
            case .GUESS_NUMBER:
                self.USE_GUESS_NUMBER = methodSwitch
                if methodSwitch { DEBUG_LOG("Enable Guess Number.") }
        }
    }

    func startSolve() -> ReturnCode {
        var tryTimes = 0
        var lastUnknNumOfAns = mainSolver.getNumOfUnknown()

        repeat {
            var narrowAns = 0
            var unknownAns = 0
            var result = 0

            tryTimes += 1
            DEBUG_LOG("This is \(tryTimes) times try to solve this puzzle")

            unknownAns = mainSolver.getNumOfUnknown()
            DEBUG_LOG("You have \(unknownAns) number to solve.")

            if USE_NARROW_METHOD_1 {
                result = mainSolver.methodNarrowCandList1()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 1.")
            }

            if USE_NARROW_METHOD_2 {
                result = mainSolver.methodNarrowCandList2()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 2.")
            }

            if USE_NARROW_METHOD_3 {
                result = mainSolver.methodNarrowCandList3()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 3.")
            }

            if USE_NARROW_METHOD_4 {
                result = mainSolver.methodNarrowCandList4()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 4.")
            }

            if USE_NARROW_METHOD_5 {
                result = mainSolver.methodNarrowCandList5()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 5.")
            }

            if USE_NARROW_METHOD_6 {
                result = mainSolver.methodNarrowCandList6()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 6.")
            }

            if USE_NARROW_METHOD_7 {
                result = mainSolver.methodNarrowCandList7()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 7.")
            }

            if USE_NARROW_METHOD_8 {
                result = mainSolver.methodNarrowCandList8()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Narrow Mehod 8.")
            }

            result = mainSolver.methodFindAnswer1()
            if result == ERROR { return ERROR }
            unknownAns -= result
            DEBUG_LOG("Finded \(result) answers by Solve Mehod 1.")
            if TRACE {
                print("\nAfter methodFindAnswer1")
                printSudokuArray()
            }

            result = mainSolver.methodFindAnswer2()
            if result == ERROR { return ERROR }
            unknownAns -= result
            DEBUG_LOG("Finded \(result) answers by Solve Mehod 2.")
            if TRACE {
                print("\nAfter methodFindAnswer2")
                printSudokuArray()
            }

            if USE_GUESS_NUMBER && unknownAns == lastUnknNumOfAns && narrowAns == 0 {
                result = mainSolver.methodGuessNumber()
                if result == ERROR { return ERROR }
                narrowAns += result
                DEBUG_LOG("Narrowed \(result) answers by Guess Number Mehod.")
            }

            if unknownAns == 0 {
                DEBUG_LOG("Use \(tryTimes) times to solved this puzzle")
                break
            } else if unknownAns == lastUnknNumOfAns && narrowAns == 0 {
                if DEBUG {
                    print("\nResult:")
                    mainSolver.printCand(SHOWCANDLISTNUM)
                }
                return FAIL
            }

            DEBUG_LOG("finded = \(lastUnknNumOfAns-unknownAns)")
            DEBUG_LOG("narrowAns = \(narrowAns)")
            DEBUG_LOG("unknownAns = \(unknownAns)")

            if DEBUG { printSudokuArray(); printCandList() }

            lastUnknNumOfAns = unknownAns
            if DEBUG_BREAK && tryTimes == DEBUG_TIMES{ return FAIL }
        }
        while true;

        if let numState = checkAnswer() {
            print("You get wrong Answer On", terminator: "\t")
            print("Column:\(numState.column), Rol:\(numState.row)",
                terminator: " ")
            print("Number:\(numState.number)")
            return ERROR
        }

        return SUCCESS
    }

    func printSudokuArray() {
        mainSolver.printSudoku()
    }

    func printCandList() {
        mainSolver.printCand()
    }

    func printSudokuNumber() {
        mainSolver.printSudokuNumber()
    }
}

func stringtToIntArray(strNum: String) -> [Int] {
    var charArray = [Int]()
    for i in strNum {
        if let value = Int(String(i)) { charArray.append(value) }
        else { charArray.append(0) }
    }
    return charArray
}

func sudokuCracker() {
    let sudokuIns: Sudoku

    var sudokuArray = [[Int]]()

    while let input = readLine() {
        sudokuArray.append(stringtToIntArray(strNum: input))
    }

    if sudokuArray.count != ColNumber {
        print("Input ERROR!")
        return
    }
    for array in sudokuArray {
        if array.count != RowNumber {
            print("Input ERROR!")
            return
        }
    }

    print("Hello Sudoku!")
    if let ins = Sudoku(sudokuArray) {
        sudokuIns = ins
    } else {
        print("Entered a illegal sudoku Puzzle!")
        print("Please try a NEW one.")
        return
    }

    print("\nQuest!")
    sudokuIns.printSudokuArray()
    if DEBUG {
        print("\nCandidate List Array!")
        sudokuIns.printCandList()
    }

    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_1, USE_NARROW_METHOD_1)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_2, USE_NARROW_METHOD_2)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_3, USE_NARROW_METHOD_3)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_4, USE_NARROW_METHOD_4)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_5, USE_NARROW_METHOD_5)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_6, USE_NARROW_METHOD_6)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_7, USE_NARROW_METHOD_7)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_8, USE_NARROW_METHOD_8)
    sudokuIns.setUseMethod(Sudoku.Method.GUESS_NUMBER, USE_GUESS_NUMBER)

    let res = sudokuIns.startSolve()
    if res == ERROR {
        if DEBUG {
            sudokuIns.printSudokuArray()
            sudokuIns.printCandList()
        }
        print("Entered a illegal sudoku Array!")
        print("Please try a NEW one.")
    } else if res == FAIL {
        print("Sorry I can NOT find the answer. Orz")
        sudokuIns.printSudokuArray()
    } else {
        print("\nAnswer!")
        sudokuIns.printSudokuArray()
        print("Number List:")
        sudokuIns.printSudokuNumber()
    }
}

func sudokuTrace(_ sudokuArray: [[Int]]) -> ReturnCode {
    let sudokuIns: Sudoku

    if sudokuArray.count != ColNumber {
        return ERROR
    }
    for array in sudokuArray {
        if array.count != RowNumber {
            return ERROR
        }
    }

    if let ins = Sudoku(sudokuArray) {
        sudokuIns = ins
    } else {
        print("Entered a illegal sudoku Puzzle!")
        print("Please try a NEW one.")
        return ERROR
    }

    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_1, USE_NARROW_METHOD_1)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_2, USE_NARROW_METHOD_2)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_3, USE_NARROW_METHOD_3)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_4, USE_NARROW_METHOD_4)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_5, USE_NARROW_METHOD_5)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_6, USE_NARROW_METHOD_6)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_7, USE_NARROW_METHOD_7)
    sudokuIns.setUseMethod(Sudoku.Method.NARROW_METHOD_8, USE_NARROW_METHOD_8)
    sudokuIns.setUseMethod(Sudoku.Method.GUESS_NUMBER, USE_GUESS_NUMBER)

    let res = sudokuIns.startSolve()
    if res == ERROR {
        print("Entered a illegal sudoku Array!")
        print("Please try a NEW one.")
        return ERROR
    } else if res == FAIL {
        return FAIL
    }

    return SUCCESS
}

func createSudokuQuestion() {
    var sudokuArray = [[Int]]()
    var sudokuTemp = [[Int]]()
    var ret = FAIL
    var QuxCount = MinQuxNumber

    while let input = readLine() {
        sudokuArray.append(stringtToIntArray(strNum: input))
    }

    if sudokuArray.count != ColNumber {
        print("Input ERROR!")
        return
    }
    for array in sudokuArray {
        if array.count != RowNumber {
            print("Input ERROR!")
            return
        }
    }

    // TODO: Limit for online complier
    var count = 50

    repeat {

        var pos:Int
        sudokuTemp = Array(sudokuArray)

        srandom(UInt32(NSDate().timeIntervalSince1970))

        repeat {
            pos = random() % NumberOfSudoku
        } while sudokuArray[pos/ColNumber][pos%ColNumber] == 0

        sudokuArray[pos/ColNumber][pos%ColNumber] = 0
        sudokuArray[ColNumber-pos/ColNumber-1][ColNumber-pos%ColNumber-1] = 0

        ret = sudokuTrace(sudokuArray)

        if ret == SUCCESS { QuxCount -= 2 }
        else if QuxCount > 0  { sudokuArray = Array(sudokuTemp); ret = SUCCESS }

        count -= 1

    } while ret == SUCCESS && count > 0

    var QuxNumber = 0
    for col in sudokuArray {
        for num in col {
            if num == 0 { QuxNumber += 1 }
        }
    }
    print("Question Number Count is \(QuxNumber).")

    print("┌---┬---┬---┬-┬---┬---┬---┬-┬---┬---┬---┐")
    print("│", terminator: "")
    for (i, numCol) in sudokuArray.enumerated() {
        if i > 0  {
            if i % 3 == 0 {
                print("├---┼---┼---┼-┼---┼---┼---┼-┼---┼---┼---┤")
            }

            print("├---┼---┼---┼-┼---┼---┼---┼-┼---┼---┼---┤")
            print(terminator: "│")
        }

        for (j, number) in numCol.enumerated() {
            if j > 0 && j % 3 == 0 { print(terminator: " │") }
            if number == 0 { print("  ", terminator: " │") }
            else { print(" \(number)", terminator: " │") }
        }

        print()
    }
    print("└---┴---┴---┴-┴---┴---┴---┴-┴---┴---┴---┘")
}

// let startTimestamp = NSDate().timeIntervalSince1970

sudokuCracker()
// createSudokuQuestion()

// let endTimestamp = NSDate().timeIntervalSince1970
// let timeSpend = endTimestamp - startTimestamp
// print("Spend \(timeSpend) seconds to slove this questions")
