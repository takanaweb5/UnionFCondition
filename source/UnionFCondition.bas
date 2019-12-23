Attribute VB_Name = "UnionFCondition"
Option Explicit
'Option Private Module

Private Type TSaveInfo
    NewAppliesTo As Range   '�Đݒ肳����Z���͈�
    Delete       As Boolean 'True:�폜�Ώ�
End Type

'*****************************************************************************
'[�T�v] �A�N�e�B�u�V�[�g�̏����t�������𓝍�����
'[����] �Ȃ�
'[�ߒl] �Ȃ�
'*****************************************************************************
Public Sub FormatConditions()
    Call UnionFormatConditions(ActiveSheet)
End Sub

'*****************************************************************************
'[�T�v] ���[�N�V�[�g���̏����t�������𓝍�����
'[����] �Ώۂ̃��[�N�V�[�g
'[�ߒl] �Ȃ�
'*****************************************************************************
Private Sub UnionFormatConditions(ByRef objWorksheet As Worksheet)
    Dim FConditions As FormatConditions
    Set FConditions = objWorksheet.Cells.FormatConditions
    If FConditions.Count = 0 Then
        Exit Sub
    End If
    
    ReDim SaveArray(1 To FConditions.Count) As TSaveInfo
    Dim i As Long
    Dim j As Long
    
    '�����t���������������LOOP���A�����o���邩�ǂ����̏���SaveArray�ɐݒ�
    For i = FConditions.Count To 1 Step -1
        For j = 1 To i - 1
            If IsSameFormatCondition(FConditions(i), FConditions(j)) Then
                '(i)��(j)����������΁A�����(i)���폜���āA�O����(j)�ɓ���
                If SaveArray(j).NewAppliesTo Is Nothing Then
                    Set SaveArray(j).NewAppliesTo = Application.Union(FConditions(i).AppliesTo, FConditions(j).AppliesTo)
                Else
                    Set SaveArray(j).NewAppliesTo = Application.Union(FConditions(i).AppliesTo, SaveArray(j).NewAppliesTo)
                End If
                SaveArray(i).Delete = True
            End If
        Next
    Next
    
    '�����t���������������폜���A�O���̏����t�������ɓ���
    For i = FConditions.Count To 1 Step -1
        If SaveArray(i).Delete = True Then
            Call FConditions(i).Delete
        Else
            If Not (SaveArray(i).NewAppliesTo Is Nothing) Then
                '�����t�������̓���
                Call FConditions(i).ModifyAppliesToRange(SaveArray(i).NewAppliesTo)
            End If
        End If
    Next

    'A1,A2,A3 �� A1:A3 �̂悤�ɗ̈�𐮗�
    Dim objWk As Range
    'FormatConditions�����k�������ߍĐݒ�
    Set FConditions = objWorksheet.Cells.FormatConditions
    For i = FConditions.Count To 1 Step -1
        With FConditions(i)
            If .AppliesTo.Areas.Count > 1 Then
                Set objWk = .AppliesTo
                'A1,A2,A3 �� A1:A3 �̂悤�ɗ̈�𐮗�
                Set objWk = Application.Intersect(objWk, objWk)
                '�̈悪���ォ����Ԃ悤�Ƀ\�[�g���� ��:E:F,B:B �� B:B,E:F
                Set objWk = SortAreas(objWk)
                Call .ModifyAppliesToRange(objWk)
            End If
        End With
    Next
End Sub

'*****************************************************************************
'[�T�v] ��ԍ���̃Z�����擾����
'[����] �����t�������̓K�p�͈�
'[�ߒl] ��ԍ���̃Z��
'*****************************************************************************
Private Function GetTopLeftCell(ByRef objRange As Range) As Range
    Dim objArea As Range
    Dim lngRow As Long
    Dim lngCol As Long
    lngRow = Rows.Count
    lngCol = Columns.Count
    
    For Each objArea In objRange.Areas
        With objArea.Cells(1)
            lngRow = WorksheetFunction.Min(.Row, lngRow)
            lngCol = WorksheetFunction.Min(.Column, lngCol)
        End With
    Next
    Set GetTopLeftCell = Cells(lngRow, lngCol)
End Function

'*****************************************************************************
'[�T�v] ��������я�������v���邩����
'[����] ��r�Ώۂ�FormatCondition�I�u�W�F�N�g
'[�ߒl] True:��v
'*****************************************************************************
Private Function IsSameFormatCondition(ByRef F1 As Object, ByRef F2 As Object) As Boolean
    IsSameFormatCondition = False
    If Not (TypeOf F1 Is FormatCondition) Then
        Exit Function
    End If
    If Not (TypeOf F2 Is FormatCondition) Then
        Exit Function
    End If

'    Select Case F1.Type
'        '�Z���̒l�A�����A������A���� �̂ݔ���ΏۂƂ���@���@FormatCondition�͂��ׂđΏۂɂ���
'        Case xlCellValue, xlExpression, xlTextString, xlTimePeriod
'        Case Else
'            Exit Function
'    End Select
    
    If IsSameCondition(F1, F2) Then
        IsSameFormatCondition = IsSameFormat(F1, F2)
    End If
End Function

'*****************************************************************************
'[�T�v] ��������v���邩����
'[����] ��r�Ώۂ�FormatCondition�I�u�W�F�N�g
'[�ߒl] True:��v
'*****************************************************************************
Private Function IsSameCondition(ByRef F1 As FormatCondition, ByRef F2 As FormatCondition) As Boolean
    Dim Operator(1 To 2)      As String '���̒l�ɓ������A���̒l�̊�etc
    Dim TextOperator(1 To 2)  As String 'Type=xlTextString�̎��A���̒l���܂ށA���̒l�Ŏn�܂�etc
    Dim Text(1 To 2)          As String 'Type=xlTextString�̎��̕�����
    Dim Formula1_R1C1(1 To 2) As String '������R1C1�^�C�v�Őݒ�
    Dim Formula2_R1C1(1 To 2) As String '������R1C1�^�C�v�Őݒ�

    IsSameCondition = False
    If F1.Type <> F2.Type Then
        Exit Function
    End If
    
    '�^�C�v�ɂ���Ă͒��ڔ��肷��Ɨ�O�ƂȂ鍀�ڂ����邽�ߗ�O��}�����ĕϐ��ɐݒ�
    On Error Resume Next
    With F1
        Operator(1) = .Operator
        TextOperator(1) = .TextOperator
        Text(1) = .Text
        Formula1_R1C1(1) = Application.ConvertFormula(.Formula1, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
        Formula2_R1C1(1) = Application.ConvertFormula(.Formula2, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
    End With
    With F2
        Operator(2) = .Operator
        TextOperator(2) = .TextOperator
        Text(2) = .Text
        Formula1_R1C1(2) = Application.ConvertFormula(.Formula1, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
        Formula2_R1C1(2) = Application.ConvertFormula(.Formula2, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
    End With
    On Error GoTo 0
    
    If Operator(1) <> Operator(2) Then
        Exit Function
    End If
    If TextOperator(1) <> TextOperator(2) Then
        Exit Function
    End If
    If Text(1) <> Text(2) Then
        Exit Function
    End If
    If Formula1_R1C1(1) <> Formula1_R1C1(2) Then
        Exit Function
    End If
    If Formula2_R1C1(1) <> Formula2_R1C1(2) Then
        Exit Function
    End If
    
    IsSameCondition = True
End Function

'*****************************************************************************
'[�T�v] ��������v���邩����
'[����] ��r�Ώۂ�FormatCondition�I�u�W�F�N�g
'[�ߒl] True:��v
'*****************************************************************************
Private Function IsSameFormat(ByRef F1 As FormatCondition, ByRef F2 As FormatCondition) As Boolean
    Dim FontBold(1 To 2)      As String '�t�H���g����
    Dim FontColor(1 To 2)     As String '�t�H���g�F
    Dim InteriorColor(1 To 2) As String '�h��Ԃ��F
    Dim NumberFormat(1 To 2)  As String '�l�̕\���`�� ��F#,##0
    
    IsSameFormat = False
    
    '�ꍇ�ɂ���Ă͒��ڔ��肷��Ɨ�O�ƂȂ鍀�ڂ����邱�Ƃ��l�����ė�O��}�����ϐ��ɐݒ�
    On Error Resume Next
    With F1
        FontBold(1) = .Font.Bold
        FontColor(1) = .Font.Color
        InteriorColor(1) = .Interior.Color
        NumberFormat(1) = .NumberFormat
    End With
    With F2
        FontBold(2) = .Font.Bold
        FontColor(2) = .Font.Color
        InteriorColor(2) = .Interior.Color
        NumberFormat(2) = .NumberFormat
    End With
    On Error GoTo 0
    
    If FontBold(1) <> FontBold(2) Then
        Exit Function
    End If
    If FontColor(1) <> FontColor(2) Then
        Exit Function
    End If
    If InteriorColor(1) <> InteriorColor(2) Then
        Exit Function
    End If
    If NumberFormat(1) <> NumberFormat(2) Then
        Exit Function
    End If
    
    IsSameFormat = True
End Function

'*****************************************************************************
'[�T�v] Debug�p�̃Z���֐�
'[����] objCell:�����t�������̐ݒ肳�ꂽ�Z���An:FormatConditions�̉��ԖځH
'       InfoNo:�ʂ̏���\�����������As(i)��Index��ݒ�
'[�ߒl] ��FType:1 Operator:4 TextOperator:# Text:# Formula1:=0 Formula2:#  Formula1:=0 Formula2:# AppliesTo:A1:A20
'*****************************************************************************
Public Function GetFConditionStr(objCell As Range, ByVal n As Long, Optional ByVal InfoNo As Long = 0) As String
    Dim objFCondition As Object
    Set objFCondition = objCell.FormatConditions(n)
        
    Dim s(1 To 11)
    Dim i As Long
    For i = 1 To UBound(s)
        s(i) = "#" '�G���[�̎�
    Next
    
    On Error Resume Next
    With objFCondition
        s(1) = .Type
        s(2) = TypeName(objFCondition)
        s(3) = .Operator
        s(4) = .TextOperator
        s(5) = .Text
        s(6) = .Formula1
        s(7) = .Formula2
        s(8) = Application.ConvertFormula(.Formula1, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
        s(9) = Application.ConvertFormula(.Formula2, xlA1, xlR1C1, , GetTopLeftCell(.AppliesTo))
        s(10) = .AppliesTo.AddressLocal(False, False)
        s(11) = GetTopLeftCell(.AppliesTo).AddressLocal(False, False)
    End With
    On Error GoTo 0
    
    If InfoNo > 0 Then
        GetFConditionStr = s(InfoNo)
    Else
        Dim strMsg As String
        strMsg = "Type:{1} TypeName:{2} Operator:{3} TextOperator:{4} Text:{5} Formula1:{6} Formula2:{7}  Formula1:{8} Formula2:{9} AppliesTo:{10} TopLeftCell:{11}"
        For i = 1 To UBound(s)
            strMsg = Replace(strMsg, "{" & i & "}", s(i))
        Next
        GetFConditionStr = strMsg
    End If
End Function

'*****************************************************************************
'[�T�v] �̈悪���ォ����Ԃ悤�Ƀ\�[�g���� ��:E:F,B:B �� B:B,E:F
'[����] �����t�������̓K�p�͈�
'[�ߒl] �\�[�g��̓K�p�͈�
'*****************************************************************************
Private Function SortAreas(ByRef objRange As Range) As Range
    ReDim SortArray(1 To objRange.Areas.Count) As Currency
    Dim i As Long
    Dim j As Long
    
    'Sort�Ώۂ̔z����쐬
    For i = 1 To objRange.Areas.Count
        With objRange.Areas(i)
            '��5���͗�ԍ��A��7���͍s�ԍ��A��4����Index
            SortArray(i) = CCur(Format(.Column, "00000") & _
                                Format(.Row, "0000000") & _
                                Format(i, "0000"))
        End With
    Next
    
    'Sort
    Dim Swap As Currency
    For i = objRange.Areas.Count To 1 Step -1
        For j = 1 To i - 1
            If SortArray(j) > SortArray(j + 1) Then
                Swap = SortArray(j)
                SortArray(j) = SortArray(j + 1)
                SortArray(j + 1) = Swap
            End If
        Next j
    Next i
    
    '���ʐݒ�
    j = Right(SortArray(1), 4) 'Index=��4��
    Set SortAreas = objRange.Areas(j)
    For i = 2 To UBound(SortArray)
        j = Right(SortArray(i), 4) 'Index=��4��
        Set SortAreas = Application.Union(SortAreas, objRange.Areas(j))
    Next
End Function


