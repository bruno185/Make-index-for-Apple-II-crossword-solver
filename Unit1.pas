unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, math;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    makeSplitIndex: TButton;
    makeWordsFile: TButton;
    procedure DoInit(Sender: TObject);
    procedure makeSplitIndexClick(Sender: TObject);
    procedure makeWordsFileClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;


implementation
{$R *.dfm}
const
  max = 15;
  maxbyte = 48283;
  bigfile = 'ods6.txt';  // 386264 words !
  const
  hex = '123456789ABCDEF';

type
  Tdesc = array [1..maxbyte] of byte ;
  TdescRL = array [1..maxbyte*2] of byte ;

var
  //desclet : array [1..390] of Tdesc;
  desc, descout : Tdesc;
  descRL : TdescRL;
  bw : integer;
  big : array [1..maxbyte*8] of string;
  divider, part, mots : integer;
  wordfile : string;

// ********************************************

function fillbig(wordfile: string) : integer;
// loads a file and populate big[] array
var
  filin : textfile;
  i: integer;
  s : string;
begin
  AssignFile(filin,wordfile);
  reset(filin);
  i := 0;
  while not(eof(filin)) do
  begin
    inc(i);
    readln(filin,s);
    big[i] := s;
  end;
  closefile(filin);
  fillbig := i;
end;


procedure runlength2(bytes:integer);
// run length compression on desc array to descRL
var
  i : integer;
  pos : integer;
  b, savb, len : byte;

begin
  fillchar(descRL,sizeof(descRL),0);
  pos := 1;
  len := 1;
  // 1st byte --> in descRL
  b := desc[1];
  descRL[pos] := len;
  descRL[pos+1] := b;
  savb := b;
  bw := 1;


  for i := 2 to bytes do
  begin
    b := desc[i];
    if (len = 255) or (b<>savb) then
    begin
      pos := pos + 2;
      len := 1;
      inc(bw);
    end
    else inc(len);

    descRL[pos] := len;
    descRL[pos+1] := b;
    savb := b;
  end;
end;


function unrunlength : integer;
// uncompress descRL into descout
var
  i,j, pos : integer;

  begin
    fillchar(descout,sizeof(descout),0);
    pos  := 0;
    i := 1;
    while i < bw*2 do
    begin
      for j := 1 to descRL[i] do
        begin
          inc (pos);
          descout[pos] := descRL[i+1];
        end;
      i := i +2;
    end;
    unrunlength := pos;
  end;

procedure compare;
// compare desc and descout
var
  i,diff : integer;
  pos : integer;
begin
  diff  := 0;
  pos := 0;
  form1.Memo1.Lines.Add('Sart compare');
  for i := 1 to maxbyte do
  begin
    pos := pos + 8;

    if desc[i] <> descout[i]  then
    begin
      inc(diff);
      with form1.Memo1 do
      Lines.Add(inttostr((i)) + ' ' + inttostr(desc[i])
      + ' ' + inttostr(descout[i]) + ' ' + inttostr(pos)
      + ' ' + big[pos]) ;
    end;
  end;
  Form1.Memo1.Lines.Add('difference : ' + IntToStr(diff));
  form1.Memo1.Lines.Add('Stop compare');
end;

procedure makeLengthIndex;
var
  i, l, curpart, debut, fin, pos : integer;
  tempodiv, tempomod , val, bytes : integer;
  fname : string;
  f : file of byte;
begin

  for l := 2 to max do
  for curpart := 1 to 4 do
  begin
    fillchar(desc,sizeof(desc),0);
    fname := 'LG'+hex[l]+'P'+inttostr(curpart);
    assignfile(f, fname);
    rewrite(f);
    form1.memo1.Lines.Add(fname);

    // populate desc array
    debut := (curpart-1)*(mots div divider)+1 ;
    fin := curpart*(mots div divider);

    for i := debut to fin do
      begin
        if length(big[i])= l then
        begin
          pos := (curpart-1)*(mots div divider);

          tempodiv := (i-1-pos) div 8 + 1;    // byte in desc
          tempomod := (i-1-pos) mod 8;        // bit in byte
          val := round(power(single(2),single(tempomod)));

          // poke bit in right byte and in the right position
          desc[tempodiv] :=  desc[tempodiv] + val;
        end;
      end;

    // RLE compress
    if mots mod (divider *8) = 0  then bytes := mots div divider div 8
    else bytes := mots div divider div 8 + 1;
    runlength2(bytes);

    // save rle file to disk
    for i := 1 to bw*2 do
    begin
       write(f,descRL[i]);
    end;
    closefile(f);

    // save index file to disk
    if mots mod (divider *8) = 0  then bytes := mots div divider div 8
    else bytes := mots div divider div 8 + 1;
    fname := fname+'.ind';
    Assignfile(f,fname);
    rewrite(f);
    for i := 1 to bytes do
    begin
       write(f,desc[i]);
    end;
    closefile(f);
  end;
end;

function readdata (letter,rank : byte) : integer;
// load data and fill desc array
var
  s : string;
  i, j : integer;
  tempodiv, tempomod, pos : integer;
  val : byte;
  found : boolean;
  wordfound : integer;
  debut, fin : integer;
  //maxindex : integer;

begin
  // init
  fillchar(desc,sizeof(desc),0);  // empty desc array

  wordfound := 0;
  debut := (part-1)*(mots div divider)+1 ;
  fin := part*(mots div divider);   // if divider = 4 : fin = 12071

  // for i := 1 to mots do
  for i := debut to fin do
    begin
    s := big[i];    // read strings in big array
   { if i = fin then
    begin
      found := false;
    end;   }

    // if letter matches : update desc array
    //if s[rank] = char(letter) then   //==> range problem s='AA' but S[13] = 'A' !!!!
    found := false;
    for j := 1 to length(s) do
        if (j = rank) and (s[j]=char(letter)) then
        found := true;

    if found  then
    begin
      inc(wordfound);
      //tempodiv := (i-1) div 8 + 1;    // byte in desc
      //tempomod := (i-1) mod 8 ;        // bit in byte
      //val := round(power(single(2),single(tempomod)));

      pos := (part-1)*(mots div divider);
      // (i-1)*(words div divider)+1
      tempodiv := (i-1-pos) div 8 + 1;    // byte in desc
      tempomod := (i-1-pos) mod 8;        // bit in byte
      val := round(power(single(2),single(tempomod)));

      // poke bit in right byte and in the right position
      desc[tempodiv] :=  desc[tempodiv] + val;
      //if tempodiv > maxindex then maxindex := tempodiv;

      // application.ProcessMessages;
    end;
    //inc(len[length(s)]);

  end;

  with Form1 do
  begin
    //memo1.Lines.Add('nombre total de mots : ' + inttostr(cnt));
    //memo1.Lines.Add('nombre de mots de 10 lettres ou moins : ' + inttostr(inf10));
    //for i := 1 to max do
    //memo1.Lines.Add('nombre de mots de '+ inttostr(i) +  ' lettres   : ' + inttostr(len[i]));
    memo1.Lines.Add(char(letter)+' '+ inttostr(rank));
  end;
  readdata := wordfound;
  //form1.Memo1.Lines.Add('Max index = '+inttostr(maxindex));
end;


function makeindex(letter, rank : integer) : integer;
// populate desc, RL compress, save binary RLE and non RLE files, uncompress and compare
// according to inputs

var
  bytes, wfound, total : integer;
  j : integer;
  f : file of byte;
  b : byte;
  indexfile : string;

begin
  fillchar(desc,sizeof(desc),0);        // empty desc

  if mots mod (divider *8) = 0  then bytes := mots div divider div 8
  else bytes := mots div divider div 8 + 1;

  // populate desc
  wfound := readdata(ord(letter),rank);
  // Run Length compress
  runlength2(bytes);

  // save index file and RL file

  indexfile := char(letter)+ hex[rank] +'P'+inttostr(part);

  // save index to disk
  Assignfile(f,indexfile+'.ind');
  rewrite(f);
  for j := 1 to bytes do
  begin
     write(f,desc[j]);
  end;
  closefile(f);

  // save RLE to disk
  Assignfile(f,indexfile);
  rewrite(f);
  for j := 1 to bw*2 do
  begin
     write(f,descRL[j]);
  end;
  closefile(f);

  form1.memo1.Lines.Add(inttostr(unrunlength));
  compare;

  // read RLE file
  // and count bytes (= sum of odd bytes)
  Assignfile(f,indexfile);
  reset(f);
  total := 0;
  for j := 1 to bw*2 do
  begin
    read(f,b);
    if j mod 2 = 1 then total := total + b;
  end;
  closefile(f);
  makeindex := total;
end;

procedure TForm1.makeWordsFileClick(Sender: TObject);
var
  f : file of byte;
  i,j : integer;
  b : byte;
  s : string;
begin
  memo1.Clear;
  AssignFile(f,'WORDS');
  rewrite(f);
  memo1.Clear;
  memo1.Lines.Add('Creating words file...') ;
  for i := 1 to mots do
    begin
      s := big[i];
      if length(s) < max+1  then
      for j := 1 to max-length(s)+1 do s := s + char(0);

      for j := 1 to length(s) do
      begin
        b := byte(s[j]);
        write(f,b);
      end;
  end;
  closefile(f);
  memo1.Lines.Add('File created ('+ inttostr(mots) + ') words.');
end;

procedure TForm1.DoInit(Sender: TObject);
begin
  divider := 4;
  wordfile := 'ods6.txt';
  mots := fillbig(wordfile);

end;

procedure TForm1.makeSplitIndexClick(Sender: TObject);
// Create all index files for all letters and position
var
total : integer;
letter, rank : integer;

begin
  memo1.Clear;
  for letter := ord('A')to ord('Z') do
  for rank := 1 to max do
  begin
    for part := 1 to 4 do
    total := makeindex(letter,rank);
    memo1.Lines.Add('Total bytes : '+inttostr(total));
  end;
  makeLengthIndex;
  memo1.Lines.Add('End of process.');
end;

end.
