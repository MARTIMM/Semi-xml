use v6.c;
use Test;

ok $x ~~ Int, 'T0';
is $x, 10, 'T1';

    my Int \$x = 10;

<__PARENT_CONTAINER__>
  <pre class="test-block-code">
  ok $x ~~ Int, '<b>T0</b>';
  is $x, 10, '<b>T1</b>';
  </pre>

  <table class="test-table">
  <tr>
  <_CHECK_MARK_ test-code="T0"/>
  <td class="test-comment"><b>T0: </b>Type is integer</td></tr></table>
  </__PARENT_CONTAINER__>

<__PARENT_CONTAINER__>
  <table class="test-table">
  <tr>
  <_CHECK_MARK_ test-code="T1"/>
  <td class="test-comment"><b>T1: </b>x is 10</td></tr>
  </table>
</__PARENT_CONTAINER__>


done-testing;
