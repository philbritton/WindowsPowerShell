## UI Automation v 1.10 -- REQUIRES the Reflection module
## 
# WASP 2.0 is getting closer, but this is still just a preview:
# -- a lot of the commands have weird names still because they're being generated ignorantly
# -- eg: Invoke-Toggle.Toggle and  Invoke-Invoke.Invoke

# v 1.7  - Fixes using multiple checks like: Select-UIElement Red: Edit
# v 1.8  - Fixes .Net version problems: specifying CSharpVersion3 when in PowerShell 2
# v 1.9  - Fix bug with Select-UIElement by processName / processId
# v 1.10 - Add the super-flexible but super-user-only -PropertyValue parameter to Select-UIElement

# IF your PowerShell is running in .Net 4
if($PSVersionTable.CLRVersion -gt "4.0") {
    $Language = "CSharp" # Version 4
    Add-Type -AssemblyName "UIAutomationClient, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
    Add-Type -AssemblyName "UIAutomationTypes, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
} else {
    # In PowerShell 2, we need to use the .Net 3 version
    $Language = "CSharpVersion3" 
    Add-Type -AssemblyName "UIAutomationClient, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
    Add-Type -AssemblyName "UIAutomationTypes, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
}


$SWA = "System.Windows.Automation"
#  Add-Accelerator InvokePattern      "$SWA.InvokePattern"                -EA SilentlyContinue
#  Add-Accelerator ExpandPattern      "$SWA.ExpandCollapsePattern"        -EA SilentlyContinue
#  Add-Accelerator WindowPattern      "$SWA.WindowPattern"                -EA SilentlyContinue
#  Add-Accelerator TransformPattern   "$SWA.TransformPattern"             -EA SilentlyContinue
#  Add-Accelerator ValuePattern       "$SWA.ValuePattern"                 -EA SilentlyContinue
#  Add-Accelerator TextPattern        "$SWA.TextPattern"                  -EA SilentlyContinue

# This is what requires the Reflection module:
Add-Accelerator Automation         "$SWA.Automation"                   -EA SilentlyContinue
Add-Accelerator AutomationElement  "$SWA.AutomationElement"            -EA SilentlyContinue
Add-Accelerator TextRange          "$SWA.Text.TextPatternRange"        -EA SilentlyContinue
#####  Conditions
Add-Accelerator Condition          "$SWA.Condition"                    -EA SilentlyContinue
Add-Accelerator AndCondition       "$SWA.AndCondition"                 -EA SilentlyContinue
Add-Accelerator OrCondition        "$SWA.OrCondition"                  -EA SilentlyContinue
Add-Accelerator NotCondition       "$SWA.NotCondition"                 -EA SilentlyContinue
Add-Accelerator PropertyCondition  "$SWA.PropertyCondition"            -EA SilentlyContinue
#####  IDentifiers
Add-Accelerator AutoElementIds     "$SWA.AutomationElementIdentifiers" -EA SilentlyContinue
Add-Accelerator TransformIds       "$SWA.TransformPatternIdentifiers"  -EA SilentlyContinue

##### Patterns:
$patterns = Get-Type -Assembly UIAutomationClient -Base System.Windows.Automation.BasePattern 
            #| Where { $_ -ne [System.Windows.Automation.InvokePattern] }


Add-Type -Language $Language -ReferencedAssemblies UIAutomationClient, UIAutomationTypes -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Windows.Automation;
using System.Runtime.InteropServices;


[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
public class StaticFieldAttribute : ArgumentTransformationAttribute {
   private Type _class;

   public override string ToString() {
      return string.Format("[StaticField(OfClass='{0}')]", OfClass.FullName);
   }

   public override Object Transform( EngineIntrinsics engineIntrinsics, Object inputData) {
      if(inputData is string && !string.IsNullOrEmpty(inputData as string)) {
         System.Reflection.FieldInfo field = _class.GetField(inputData as string, BindingFlags.Static | BindingFlags.Public);
         if(field != null) {
            return field.GetValue(null);
         }
      }
      return inputData;
   }
   
   public StaticFieldAttribute( Type ofClass ) {
      OfClass = ofClass;
   }

   public Type OfClass {
      get { return _class; }
      set { _class = value; }
   }   
}

public static class UIAutomationHelper {

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern IntPtr FindWindow (string lpClassName, string lpWindowName);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern bool AttachThreadInput (int idAttach, int idAttachTo, bool fAttach);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern int GetWindowThreadProcessId (IntPtr hWnd, IntPtr lpdwProcessId);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern IntPtr SetForegroundWindow (IntPtr hWnd);

   public static AutomationElement RootElement {
      get { return AutomationElement.RootElement; }
   }


   ///<synopsis>Using Win32 to set foreground window because AutomationElement.SetFocus() is unreliable</synopsis>
   public static bool SetForeground(this AutomationElement element)
   {
      if(element == null) { 
         throw new ArgumentNullException("element");
      }

      // Get handle to the element
      IntPtr other = FindWindow (null, element.Current.Name);

      // // Get the Process ID for the element we are trying to
      // // set as the foreground element
      // int other_id = GetWindowThreadProcessId (other, IntPtr.Zero);
      // 
      // // Get the Process ID for the current process
      // int this_id = GetWindowThreadProcessId (Process.GetCurrentProcess().Handle, IntPtr.Zero);
      // 
      // // Attach the current process's input to that of the 
      // // given element. We have to do this otherwise the
      // // WM_SETFOCUS message will be ignored by the element.
      // bool success = AttachThreadInput(this_id, other_id, true);

      // Make the Win32 call
      IntPtr previous = SetForegroundWindow(other);

      return !IntPtr.Zero.Equals(previous);
   }
}
"@
            
## TODO: Write Get-SupportedPatterns or rather ... 
## Get-SupportedFunctions (to return the names of the functions for the supported patterns)
## TODO: Support all the "Properties" too
## TODO: Figure out why Notepad doesn't support SetValue
## TODO: Figure out where the menus support went
ForEach($pattern in $patterns){
   $pattern | Add-Accelerator
   $PatternFullName = $pattern.FullName
   $PatternName = $Pattern.Name -Replace "Pattern","."
   $newline = "`n`t`t"
   
   New-Item "Function:ConvertTo-$($Pattern.Name)" -Value "
   param(
      [Parameter(ValueFromPipeline=`$true)][Alias('Element','AutomationElement')][AutomationElement]`$InputObject
   )
   process { 
      trap { 
         if(`$_.Exception.Message -like '*Unsupported Pattern.*') {
            Write-Error `"Cannot get ```"$($Pattern.Name)```" from that AutomationElement, `$(`$_)` You should try one of: `$(`$InputObject.GetSupportedPatterns()|%{```"'```" + (`$_.ProgrammaticName.Replace(```"PatternIdentifiers.Pattern```",```"```")) + ```"Pattern'```"})`"; continue;
         }
      }
      Write-Output `$InputObject.GetCurrentPattern([$PatternFullName]::Pattern).Current
   }"
   
   $pattern.GetMethods() | 
   Where { $_.DeclaringType -eq $_.ReflectedType -and !$_.IsSpecialName } | 
   ForEach {
      $FunctionName = "Function:Invoke-$PatternName$($_.Name)"
      $Position = 1
      
      if (test-path $FunctionName) { remove-item $FunctionName }
      $Parameters = @("$newline[Parameter(ValueFromPipeline=`$true)]"+
                      "$newline[Alias('Parent','Element','Root','AutomationElement')]"+
                      "$newline[AutomationElement]`$InputObject"
                      ) + 
                    @(
                      "[Parameter()]$newline[Switch]`$Passthru"
                     ) + 
                    @($_.GetParameters() | % { "[Parameter(Position=$($Position; $Position++))]$newline[$($_.ParameterType.FullName)]`$$($_.Name)" })
      $Parameters = $Parameters -Join "$newline,$newline"
      $ParameterValues = '$' + (@($_.GetParameters() | Select-Object -Expand Name ) -Join ', $')

      $definition = @"
   param(
      $Parameters
   )
   process { 
      ## trap { Write-Warning "`$(`$_)"; break }
      `$pattern = `$InputObject.GetCurrentPattern([$PatternFullName]::Pattern)
      if(`$pattern) {
         `$Pattern.$($_.Name)($(if($ParameterValues.Length -gt 1){ $ParameterValues }))
      }
      if(`$passthru) {
         `$InputObject
      }
   }
"@
      
      trap {
         Write-Warning $_
         Write-Host $definition -fore cyan
      }
      New-Item $FunctionName -value $definition
   }
   
   $pattern.GetProperties() | 
   Where { $_.DeclaringType -eq $_.ReflectedType -and $_.Name -notmatch "Cached|Current"} |
   ForEach {
      $FunctionName = "Function:Get-$PatternName$($_.Name)".Trim('.')
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      )      
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         `$pattern = `$AutomationElement.GetCurrentPattern([$PatternFullName]::Pattern)
         if(`$pattern) {
            `$pattern.'$($_.Name)'
         }
      }"
   }
   ## So far this seems to be restricted to Text (DocumentRange) elements
   $pattern.GetFields() |
   Where { $_.FieldType.Name -like "*TextAttribute"} |
   ForEach {
      $FunctionName = "Function:Get-Text$($_.Name -replace 'Attribute')"
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      )
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         `$AutomationElement.GetAttributeValue([$PatternFullName]::$($_.Name))
      }"
   }
   
   $pattern.GetFields() | Where { $_.FieldType -eq [System.Windows.Automation.AutomationEvent] } |
   ForEach {
      $Name = $_.Name -replace 'Event$'
      $FunctionName = "Function:Register-$($PatternName.Trim('.'))$Name"
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      ,
         [System.Windows.Automation.TreeScope]`$TreeScope = 'Element'
      ,
         [ScriptBlock]`$EventHandler
      )
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         [Automation]::AddAutomationEventHandler( [$PatternFullName]::$Name, `$AutomationElement, `$TreeScope, `$EventHandler )
      }"
   }
}

$FalseCondition = [Condition]::FalseCondition
$TrueCondition  = [Condition]::TrueCondition

Add-Type -AssemblyName System.Windows.Forms
Add-Accelerator SendKeys           System.Windows.Forms.SendKeys       -EA SilentlyContinue

$AutomationProperties = [system.windows.automation.automationelement+automationelementinformation].GetProperties()

Set-Alias Invoke-UIElement Invoke-Invoke.Invoke

function formatter  { END {
   $input | Format-Table @{l="Text";e={$_.Text.SubString(0,25)}}, ClassName, FrameworkId -Auto
}}

function Get-ClickablePoint {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
)
   process {
      $InputObject.GetClickablePoint()
   }
}

function Show-Window {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      Set-UIFocus $InputObject
      if($passthru) {
         $InputObject
      }        
   }
}

function Set-UIFocus {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      try {
         [UIAutomationHelper]::SetForeground( $InputObject )
         $InputObject.SetFocus()
      } catch {
         Write-Verbose "SetFocus fail, trying SetForeground"
      }
      if($passthru) {
         $InputObject
      }        
   }
}

function Send-UIKeys {
[CmdletBinding()]
param(
   [Parameter(Position=0)]
   [string]$Keys
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru
,
   [Parameter()]
   [Switch]$Async
)
   process {
      if(!$InputObject.Current.IsEnabled)
      {
         Write-Warning "The Control is not enabled!"
      }
      if(!$InputObject.Current.IsKeyboardFocusable)
      {
         Write-Warning "The Control is not focusable!"
      }
      Set-UIFocus $InputObject
      
      if($Async) {
         [SendKeys]::Send( $Keys )
      } else {
         [SendKeys]::SendWait( $Keys )
      }
      
      if($passthru) {
         $InputObject
      }      
   }
}

function Set-UIText {
[CmdletBinding()]
param(
   [Parameter(Position=0)]
   [string]$Text
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      if(!$InputObject.Current.IsEnabled)
      {
         Write-Warning "The Control is not enabled!"
      }
      if(!$InputObject.Current.IsKeyboardFocusable)
      {
         Write-Warning "The Control is not focusable!"
      }
      
      $valuePattern = $null
      if($InputObject.TryGetCurrentPattern([ValuePattern]::Pattern,[ref]$valuePattern)) {
         Write-Verbose "Set via ValuePattern!"
         $valuePattern.SetValue( $Text )
      } 
      elseif($InputObject.Current.IsKeyboardFocusable) 
      {
         Set-UIFocus $InputObject
         [SendKeys]::SendWait("^{HOME}");
         [SendKeys]::SendWait("^+{END}");
         [SendKeys]::SendWait("{DEL}");
         [SendKeys]::SendWait( $Text )
      }
      if($passthru) {
         $InputObject
      }      
   }
}

function Select-UIElement {
[CmdletBinding(DefaultParameterSetName="FromParent")]
PARAM (
   [Parameter(ParameterSetName="FromWindowHandle", Position="0", Mandatory=$true)] 
   [Alias("MainWindowHandle","hWnd","Handle","Wh")]
   [IntPtr[]]$WindowHandle=[IntPtr]::Zero,

   [Parameter(ParameterSetName="FromPoint", Position="0", Mandatory=$true)]
   [System.Windows.Point[]]$Point,

   [Parameter(ParameterSetName="FromParent", ValueFromPipeline=$true, Position=100)]
   [System.Windows.Automation.AutomationElement]$Parent = [UIAutomationHelper]::RootElement,

   [Parameter(ParameterSetName="FromParent", Position="0")]
   [Alias("WindowName")]
   [String[]]$Name,

   [Parameter(ParameterSetName="FromParent", Position="1")]
   [Alias("Type","Ct")]
   [System.Windows.Automation.ControlType]
   [StaticField(([System.Windows.Automation.ControlType]))]$ControlType,

   [Parameter(ParameterSetName="FromParent")]
   [Alias("UId")]
   [String[]]$AutomationId,

   ## Removed "Id" alias to allow get-process | Select-Window pipeline to find just MainWindowHandle
   [Parameter(ParameterSetName="FromParent", ValueFromPipelineByPropertyName=$true )]
   [Alias("Id")]
   [Int[]]$PID,

   [Parameter(ParameterSetName="FromParent")]
   [Alias("Pn")]
   [String[]]$ProcessName,

   [Parameter(ParameterSetName="FromParent")]
   [Alias("Cn")]
   [String[]]$ClassName,

   [switch]$Recurse,

   [switch]$Bare,

   [Parameter(ParameterSetName="FromParent")]
   #[Alias("Pv")]
   [Hashtable]$PropertyValue

)
process {

   Write-Debug "Parameters Found"
   Write-Debug ($PSBoundParameters | Format-Table | Out-String)

   $search = "Children"
   if($Recurse) { $search = "Descendants" }
   
   $condition = [System.Windows.Automation.Condition]::TrueCondition
   
   Write-Verbose $PSCmdlet.ParameterSetName
   switch -regex ($PSCmdlet.ParameterSetName) {
      "FromWindowHandle" {
         Write-Verbose "Finding from Window Handle $HWnd"
         $Element = $(
            foreach($hWnd in $WindowHandle) {
               [System.Windows.Automation.AutomationElement]::FromHandle( $hWnd )
            }
         )
         continue
      }
      "FromPoint" {
         Write-Verbose "Finding from Point $Point"
         $Element = $(
            foreach($pt in $Point) {
               [System.Windows.Automation.AutomationElement]::FromPoint( $pt )
            }
         )
         continue
      }
      "FromParent" {
         Write-Verbose "Finding from Parent!"
         ## [System.Windows.Automation.Condition[]]$conditions = [System.Windows.Automation.Condition]::TrueCondition
         [ScriptBlock[]]$filters = @()
         if($AutomationId) {
            [System.Windows.Automation.Condition[]]$current = $(
               foreach($aid in $AutomationId) {
                  new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::AutomationIdProperty), $aid
               }
            )
            if($current.Length -gt 1) {
               [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
            } elseif($current.Length -eq 1) {
               [System.Windows.Automation.Condition[]]$conditions += $current[0]
            }  
         }
         if($PID) {
            [System.Windows.Automation.Condition[]]$current = $(
               foreach($p in $PID) {
                  new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ProcessIdProperty), $p
               }
            )
            if($current.Length -gt 1) {
               [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
            } elseif($current.Length -eq 1) {
               [System.Windows.Automation.Condition[]]$conditions += $current[0]
            }         
         }
         if($ProcessName) {
            if($ProcessName -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($p in $ProcessName){ (Get-Process -id $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ProcessIdProperty)).ProcessName -like $p }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($p in Get-Process -Name $ProcessName) {
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ProcessIdProperty), $p.id
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }               
            }
         }
         if($Name) {
            Write-Verbose "Name: $Name"
            if($Name -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($n in $Name){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty) -like $n }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($n in $Name){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::NameProperty), $n, "IgnoreCase"
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }   
            }
         }
         if($ClassName) {
            if($ClassName -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($c in $ClassName){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ClassNameProperty) -like $c }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($c in $ClassName){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ClassNameProperty), $c, "IgnoreCase"
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }                  
            }
         }
         if($ControlType) {
            if($ControlType -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($c in $ControlType){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ControlTypeProperty) -like $c }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($c in $ControlType){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ControlTypeProperty), $c
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }                  
            }
         }
         if($PropertyValue) {
            $Property = $PropertyValue.Keys[0]
            $Value = $PropertyValue.Values[0]
            if($Value -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($c in $PropertyValue.GetEnumerator()){
                  $_.GetCurrentPropertyValue(  
                     [System.Windows.Automation.AutomationElement].GetField(
                        $c.Key).GetValue(([system.windows.automation.automationelement]))
                  ) -like $c.Value }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($c in $PropertyValue.GetEnumerator()){
                     new-object System.Windows.Automation.PropertyCondition (
                        [System.Windows.Automation.AutomationElement].GetField(
                        $c.Key).GetValue(([system.windows.automation.automationelement]))), $c.Value
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }                  
            }
         }         
         
         if($conditions.Length -gt 1) {
            [System.Windows.Automation.Condition]$condition = New-Object System.Windows.Automation.AndCondition $conditions
         } elseif($conditions) {
            [System.Windows.Automation.Condition]$condition = $conditions[0]
         } else {
            [System.Windows.Automation.Condition]$condition = [System.Windows.Automation.Condition]::TrueCondition
         }
         
         If($VerbosePreference -gt "SilentlyContinue") {
         
            function Write-Condition {
               param([Parameter(ValueFromPipeline=$true)]$condition, $indent = 0)
               process {
                  Write-Debug ($Condition | fl *  | Out-String)               
                  if($condition -is [System.Windows.Automation.AndCondition] -or $condition -is [System.Windows.Automation.OrCondition]) {
                     Write-Verbose ((" "*$indent) + $Condition.GetType().Name )
                     $condition.GetConditions().GetEnumerator() | Write-Condition -Indent ($Indent+4)
                  } elseif($condition -is [System.Windows.Automation.PropertyCondition]) {
                     Write-Verbose ((" "*$indent) + $Condition.Property.ProgrammaticName + " = '" + $Condition.Value + "' (" + $Condition.Flags + ")")
                  } else {
                     Write-Verbose ((" "*$indent) + $Condition.GetType().Name + " where '" + $Condition.Value + "' (" + $Condition.Flags + ")")
                  }
               }
            }
         
            Write-Verbose "CONDITIONS ============="
            $global:LastCondition = $condition
            foreach($c in $condition) {            
               Write-Condition $c
            }
            Write-Verbose "============= CONDITIONS"
         }
         
         if($filters.Count -gt 0) {
            $Element = $Parent.FindAll( $search, $condition ) | Where-Object { $item = $_;  foreach($f in $filters) { $item = $item | Where $f }; $item }
         } else {
            $Element = $Parent.FindAll( $search, $condition )
         }
      }  
   }
   
   Write-Verbose "Element Count: $(@($Element).Count)"
   if($Element) {
      foreach($el in $Element) {
         if($Bare) {
            Write-Output $el
         } else {
            $e = New-Object PSObject $el
            foreach($prop in $e.GetSupportedProperties() | Sort ProgrammaticName)
            {
               ## TODO: make sure all these show up: [System.Windows.Automation.AutomationElement] | gm -sta -type Property
               $propName = [System.Windows.Automation.Automation]::PropertyName($prop)
               Add-Member -InputObject $e -Type ScriptProperty -Name $propName -Value ([ScriptBlock]::Create( "`$this.GetCurrentPropertyValue( [System.Windows.Automation.AutomationProperty]::LookupById( $($prop.Id) ))" )) -EA 0
            }
            foreach($patt in $e.GetSupportedPatterns()| Sort ProgrammaticName)
            {
               Add-Member -InputObject $e -Type ScriptProperty -Name ($patt.ProgrammaticName.Replace("PatternIdentifiers.Pattern","") + "Pattern") -Value ([ScriptBlock]::Create( "`$this.GetCurrentPattern( [System.Windows.Automation.AutomationPattern]::LookupById( '$($patt.Id)' ) )" )) -EA 0
            }
            Write-Output $e
         }
      }
   }
}

}

Export-ModuleMember -cmdlet * -Function * -Alias *

#   [Cmdlet(VerbsCommon.Add, "UIAHandler")]
#   public class AddUIAHandlerCommand : PSCmdlet
#   {
#      private AutomationElement _parent = AutomationElement.RootElement;
#      private AutomationEvent _event = WindowPattern.WindowOpenedEvent;
#      private TreeScope _scope = TreeScope.Children;
#
#      [Parameter(ValueFromPipeline = true)]
#      [Alias("Parent", "Element", "Root")]
#      public AutomationElement InputObject { set { _parent = value; } get { return _parent; } }
#
#      [Parameter()]
#      public AutomationEvent Event { set { _event = value; } get { return _event; } }
#
#      [Parameter()]
#      public AutomationEventHandler ScriptBlock { set; get; }
#
#      [Parameter()]
#      public SwitchParameter Passthru { set; get; }
#
#      [Parameter()]
#      public TreeScope Scope { set { _scope = value; } get { return _scope; } }
#
#      protected override void ProcessRecord()
#      {
#         Automation.AddAutomationEventHandler(Event, InputObject, Scope, ScriptBlock);
#
#         if (Passthru.ToBool())
#         {
#            WriteObject(InputObject);
#         }
#
#         base.ProcessRecord();
#      }
#   }

# SIG # Begin signature block
# MIIarwYJKoZIhvcNAQcCoIIaoDCCGpwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPAPqjEcUcblhBQq0le4IKxgn
# Y8SgghXlMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggahMIIFiaADAgECAhADS1DyPKUAAEvdY0qN2NEFMA0GCSqGSIb3DQEBBQUAMG8x
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBLTEwHhcNMTMwMzE5MDAwMDAwWhcNMTQwNDAxMTIwMDAwWjBt
# MQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxFzAVBgNVBAcTDldlc3Qg
# SGVucmlldHRhMRgwFgYDVQQKEw9Kb2VsIEguIEJlbm5ldHQxGDAWBgNVBAMTD0pv
# ZWwgSC4gQmVubmV0dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMPj
# sSDplpNPrcGhb5o977Z7VdTm/BdBokBbRRD5hGF+E7bnIOEK2FTB9Wypgp+9udd7
# 6nMgvZpj4gtO6Yj+noUcK9SPDMWgVOvvOe5JKKJArRvR5pDuHKFa+W2zijEWUjo5
# DcqU2PGDralKrBZVfOonity/ZHMUpieezhqy98wcK1PqDs0Cm4IeRDcbNwF5vU1T
# OAwzFoETFzPGX8n37INVIsV5cFJ1uGFncvRbAHVbwaoR1et0o01Jsb5vYUmAhb+n
# qL/IA/wOhU8+LGLhlI2QL5USxnLwxt64Q9ZgO5vu2C2TxWEwnuLz24SAhHl+OYom
# tQ8qQDJQcfh5cGOHlCsCAwEAAaOCAzkwggM1MB8GA1UdIwQYMBaAFHtozimqwBe+
# SXrh5T/Wp/dFjzUyMB0GA1UdDgQWBBRfhbxO+IGnJ/yiJPFIKOAXo+DUWTAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcwYDVR0fBGwwajAzoDGg
# L4YtaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtMjAxMWEuY3Js
# MDOgMaAvhi1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vYXNzdXJlZC1jcy0yMDEx
# YS5jcmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDATCCAaQwOgYIKwYB
# BQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9y
# eS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYIGCCsGAQUFBwEBBHYwdDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEwGCCsGAQUFBzAC
# hkBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# b2RlU2lnbmluZ0NBLTEuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEFBQAD
# ggEBABv8O1PicJ3pbsLtls/jzFKZIG16h2j0eXdsJrGZzx6pBVnXnqvL4ZrF6dgv
# puQWr+lg6wL+Nxi9kJMeNkMBpmaXQtZWuj6lVx23o4k3MQL5/Kn3bcJGpdXNSEHS
# xRkGFyBopLhH2We/0ic30+oja5hCh6Xko9iJBOZodIqe9nITxBjPrKXGUcV4idWj
# +ZJtkOXHZ4ucQ99f7aaM3so30IdbIq/1+jVSkFuCp32fisUOIHiHbl3nR8j20YOw
# ulNn8czlDjdw1Zp/U1kNF2mtZ9xMYI8yOIc2xvrOQQKLYecricrgSMomX54pG6uS
# x5/fRyurC3unlwTqbYqAMQMlhP8wggajMIIFi6ADAgECAhAPqEkGFdcAoL4hdv3F
# 7G29MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0Rp
# Z2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBaFw0yNjAy
# MTAxMjAwMDBaMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQCcfPmgjwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G0ySR/6hS
# k+dy+PFGhpTFqxf0eH/Ler6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLcy7iGQEUf
# T/k5mNM7629ppFwBLrFm6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O/oBcZ3e1
# 1W9mZJRru4hJaNjR9H4hwebFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr2aFdvftW
# k+8b/HL53z4y/d0qLDJG2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM9HqLckvg
# VrUTtmPpP05JI+cGFvAlqwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAOBgNVHQ8B
# Af8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6MIIBtjCC
# AbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQW
# BBR7aM4pqsAXvkl64eU/1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun
# pyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSHu9uUkteQ
# WTP6K4feqFuAJT8Tj5uDG3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYETRvqcP2pR
# ON60Jcvwq9/FKAFUeRBGJNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3TbNwj7aqg
# TWcJ8zqAPTz7NkyQ53ak3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY1NWcEDzV
# sRwZ/4/Ia5ue+K6cmZZ40c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im3yl/Brk8
# Dr2fxIacgkdCcTKGCZlyCXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM/zGCBDQw
# ggQwAgEBMIGDMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTECEANLUPI8pQAAS91jSo3Y0QUwCQYF
# Kw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJ
# KoZIhvcNAQkEMRYEFKR+Zjk5JLMiaXtsiI70LT+07EZgMA0GCSqGSIb3DQEBAQUA
# BIIBAHshaG5r5s9YdEEYSE3IQtOgM/Ba0JJUuW9f5aTtXpAJ1qlGsguCzbtYnL4W
# yq+2K18M5TRZVGtXOrHDX8yATrMGq63oN2ttGMItCBaYIlL6UCFXmYbDFjnHEEaC
# SOGs/wOCUsW/cLNxvltZVnmj3Bm0yiYSColbtbB+EY0z5NpBfqSEfdtfAbzYiykU
# xLmWWpkJi2bBR2WNE9MFlRx/nOJfuadAu86lla9w955jO3OqWfbxtZauoLZ++Q+K
# ciyqH+Kta+w2PtINgmijV4MzpXkPR449RY1ZVJF33cy2Cn3VpX6uVOGT5Ky0+WM+
# 9qPuzIkV6Ge1ojEUUcYEW8PIUPOhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMxMTA4MTgzMTU4WjAjBgkq
# hkiG9w0BCQQxFgQUfKIlmZM9pXYkd2jg7MQjX8gw1SEwDQYJKoZIhvcNAQEBBQAE
# ggEAbwZ14BEBxPc9D23QuLsguOO6EcNgVkNw4VWx3OFeqF7MmZjDKahiK7aEQOmz
# LAw4ARtu13vVezXoiTbUESiihxT2fV1VH7xNrwizR+ww7LQ5cM0XCfxzQJV4c3lm
# tyar/C1SU46upqXANh6yLXBT8hb61Etfuo3ZHWfouNey/aklRB2vtm7MMGhSlwat
# Onz8wmQAHEg85sKBbPiWlVDWQo010JLhXdC41YISx9QkaAbJ2xlwg7dRaN4jDxXF
# PW5tmcu656a4PwLxnsULC6CNgc3oLBAXD2Ju8D9+k3qlmeZX7zZTPyhhY/WVn/Nb
# MMpMiE9p/GjzWXFTChhYom5MGw==
# SIG # End signature block
