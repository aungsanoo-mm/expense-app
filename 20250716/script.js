let sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0, sum5 = 0, total = 0, incomeTotal = 0;

const ctx = document.getElementById('expenseChart').getContext('2d');
let expenseChart = new Chart(ctx, {
  type: 'pie',
  data: {
    labels: ['1. Foods', '2. Clothes', '3. Family', '4. Health', '5. Others'],
    datasets: [{
      label: 'Expense',
      data: [0, 0, 0, 0, 0],
      backgroundColor: ['#3e95cd', '#ffa726', '#8e5ea2', '#3cba9f', '#f4c430']
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'bottom' },
      title: { display: true, text: 'July Expense Breakdown' }
    }
  }
});

function updateChart() {
  expenseChart.data.datasets[0].data = [sum1, sum2, sum3, sum4, sum5];
  expenseChart.update();
}

function updateTable(data, dayTotal) {
  const row = document.createElement("tr");
  row.innerHTML = `
    <td>${data.date}</td>
    <td>${data.details}</td>
    <td>${data.cat1}</td>
    <td>${data.cat2}</td>
    <td>${data.cat3}</td>
    <td>${data.cat4}</td>
    <td>${data.cat5}</td>
    <td><strong>${dayTotal}</strong></td>
    <td>${data.remarks}</td>
    <td>${data.income}</td>
  `;
  document.querySelector("#expense-table tbody").appendChild(row);

  document.getElementById("sum1").innerText = sum1;
  document.getElementById("sum2").innerText = sum2;
  document.getElementById("sum3").innerText = sum3;
  document.getElementById("sum4").innerText = sum4;
  document.getElementById("sum5").innerText = sum5;
  document.getElementById("sumTotal").innerHTML = `<strong>${total}</strong>`;
  document.getElementById("sumIncome").innerHTML = `<strong>${incomeTotal}</strong>`;
}

window.addEventListener("DOMContentLoaded", () => {
  fetch("/expense")
    .then(res => res.json())
    .then(expenses => {
      expenses.forEach(data => {
        const dayTotal = data.cat1 + data.cat2 + data.cat3 + data.cat4 + data.cat5;
        sum1 += data.cat1;
        sum2 += data.cat2;
        sum3 += data.cat3;
        sum4 += data.cat4;
        sum5 += data.cat5;
        total += dayTotal;
        incomeTotal += data.income;
        updateTable(data, dayTotal);
      });
      updateChart();
    })
    .catch(error => console.error("Error loading expenses:", error));
});

document.getElementById("expense-form").addEventListener("submit", function(e) {
  e.preventDefault();

  const data = {
    date: document.getElementById("date").value,
    details: document.getElementById("details").value,
    cat1: parseFloat(document.getElementById("cat1").value) || 0,
    cat2: parseFloat(document.getElementById("cat2").value) || 0,
    cat3: parseFloat(document.getElementById("cat3").value) || 0,
    cat4: parseFloat(document.getElementById("cat4").value) || 0,
    cat5: parseFloat(document.getElementById("cat5").value) || 0,
    remarks: document.getElementById("remarks").value || '',
    income: parseFloat(document.getElementById("income").value) || 0
  };

  const dayTotal = data.cat1 + data.cat2 + data.cat3 + data.cat4 + data.cat5;

  // 🟢 Update locally first
  sum1 += data.cat1;
  sum2 += data.cat2;
  sum3 += data.cat3;
  sum4 += data.cat4;
  sum5 += data.cat5;
  total += dayTotal;
  incomeTotal += data.income;
  updateTable(data, dayTotal);
  updateChart();

  // 📤 Then submit to backend
  fetch("/expense", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  })
  .then(res => res.json())
  .then(response => console.log(response.message))
  .catch(error => console.error("Backend error:", error));

  document.getElementById("expense-form").reset();
});

